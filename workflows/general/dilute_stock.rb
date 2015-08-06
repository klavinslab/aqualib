needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  # this function process fragment ids that passed task_inputs, return their PCR recipe template stock, primer aliquts, annealing temperature and length, also return samples whose stock need to be diluted.
  def fragment_recipe id, p={}
    fragment = find(:sample, { id: id })[0]
    props = fragment.properties.deep_dup
    dilute_sample_ids = []  # primer or template ids whose stock needs to be diluted
    fwd = props["Forward Primer"]
    rev = props["Reverse Primer"]
    template = props["Template"]
    length = props["Length"]
    # compute the annealing temperature
    t1 = fwd.properties["T Anneal"]
    t2 = rev.properties["T Anneal"]
    # get items associated with primers and template
    fwd_items = fwd.in "Primer Aliquot"
    rev_items = rev.in "Primer Aliquot"
    dilute_sample_ids.push fwd.id if fwd_items.empty?
    dilute_sample_ids.push rev.id if rev_items.empty?

    if template.sample_type.name == "Plasmid"
      template_items = template.in "1 ng/µL Plasmid Stock"
      if template_items.empty? && template.in("Plasmid Stock").empty?
        template_items = template.in "Gibson Reaction Result"
      elsif template_items.empty? && template.in("Plasmid Stock").any?
        dilute_sample_ids.push template.id
      end
    elsif template.sample_type.name == "Fragment"
      template_items = template.in "1 ng/µL Fragment Stock"
      dilute_sample_ids.push template.id if template_items.empty?
    elsif template.sample_type.name == "E coli strain"
      template_items = template.in "E coli Lysate"
      if template_items.length == 0
        template_items = template.in "Genome Prep"
        template_items = template_items.reverse() #so we take the last one.
      end
    elsif template.sample_type.name == "Yeast Strain"
      template_items = template.in "Lysate"
      if template_items.length == 0
        template_items = template.in "Yeast cDNA"
      end
    end

    return {
      dilute_sample_ids: dilute_sample_ids,
      fragment: fragment,
      length: length,
      fwd: fwd_items[0],
      rev: rev_items[0],
      template: template_items[0],
      tanneal: [t1,t2].min
    }
  end

  # pass primer ids here and figure out which primer needs to dilute, return the primer ids that needs to be diluted.
  def primers_need_to_dilute ids
    ids = [ids] unless ids.is_a? Array
    dilute_sample_ids = ids.select do |id|
      primer = find(:sample, id: id)[0]
      primer.in("Primer Stock").any? && primer.in("Primer Aliquot").empty?
    end
    return dilute_sample_ids
  end

  # dilute stocks of samples with ids. e.g. dilute primer stock of primer to primer aliquot, return the diluted stocks to be released in the protocol.
  def dilute_samples ids
    ids = [ids] unless ids.is_a? Array
    ids.uniq!
    dilute_stocks = ids.collect do |id|
      dilute_sample = find(:sample, id: id)[0]
      dilute_stock = dilute_sample.in(dilute_sample.sample_type.name + " Stock")[0]
    end
    template_stocks, primer_stocks = [], []
    dilute_stocks.each do |stock|
      if ["Plasmid Stock", "Fragment Stock"].include? stock.object_type.name
        template_stocks.push stock
      elsif ["Primer Stock"].include? stock.object_type.name
        primer_stocks.push stock
      end
    end

    take dilute_stocks, interactive: true, method: "boxes"

    template_diluted_stocks = []
    if template_stocks.any?
      template_stocks_need_to_measure = template_stocks.select { |s| !s.datum[:concentration] }
      while template_stocks_need_to_measure.length > 0
        data = show {
          title "Nanodrop the following template/fragment stocks."
          template_stocks_need_to_measure.each do |ts|
            get "number", var: "c#{ts.id}", label: "Go to B9 and nanodrop tube #{ts.id}, enter DNA concentrations in the following", default: 100
          end
        }
        template_stocks_need_to_measure.each do |ts|
          ts.datum = { concentration: data[:"c#{ts.id}".to_sym] }
          ts.save
        end
        template_stocks_need_to_measure = template_stocks.select { |s| !s.datum[:concentration] }
      end

      # produce 1 ng/µL Plasmid Stocks
      template_diluted_stocks = template_stocks.collect { |s| produce new_sample s.sample.name, of: s.sample.sample_type.name, as: ("1 ng/µL " + s.sample.sample_type.name + " Stock") }

      # collect all concentrations
      concs = template_stocks.collect {|s| s.datum[:concentration].to_f}
      water_volumes = concs.collect {|c| c-1}

      # build a checkable table for user
      tab = [["Newly labled tube","Template stock, 1 µL","Water volume"]]
      template_stocks.each_with_index do |s,idx|
        tab.push([template_diluted_stocks[idx].id, { content: s.id, check: true }, { content: water_volumes[idx].to_s + " µL", check: true }])
      end

      # display the dilution info to user
      show {
        title "Make 1 ng/µL Template Stocks"
        check "Grab #{template_stocks.length} 1.5 mL tubes, label them with #{template_stocks.collect {|s| s.id}}"
        check "Add template stocks and water into newly labeled 1.5 mL tubes following the table below"
        table tab
        check "Vortex and then spin down for a few seconds"
      }

    end

    primer_aliquots = []
    if primer_stocks.any?
      primer_aliquots = primer_stocks.collect { |p| produce new_sample p.sample.name, of: "Primer", as: "Primer Aliquot" }
      show {
        title "Grab #{primer_aliquots.length} 1.5 mL tubes"
        check "Grab #{primer_aliquots.length} 1.5 mL tubes, label with following ids."
        check primer_aliquots.collect { |p| "#{p}"}
        check "Add 90 µL of water into each above tube."
      }
      show {
        title "Make primer aliquots"
        note "Add 10 µL from primer stocks into each primer aliquot tube using the following table."
        table [["Primer Aliquot id", "Primer Stock, 10 µL"]].concat (primer_aliquots.collect { |p| "#{p}"}.zip primer_stocks.collect { |p| { content: p.id, check: true } })
      }
    end

    # release all the items
    release dilute_stocks, interactive: true, method: "boxes"
    return template_diluted_stocks + primer_aliquots
  end


  def arguments
    {
      io_hash: {},
      fragment_ids: [2014,6444,2007,3400],
      debug_mode: "No"
    }
  end

  def main

    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { group: "technicians", debug_mode: "Yes" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    dilute_sample_ids = io_hash[:fragment_ids].collect { |id| fragment_recipe(id)[:dilute_sample_ids] }
    dilute_sample_ids.flatten!
    dilute_samples dilute_sample_ids
    return { io_hash: io_hash }

  end

end
