needs "aqualib/lib/standard"
needs "aqualib/lib/tasking"

module Cloning

  def self.included klass
    klass.class_eval do
      include Standard
      include Tasking
    end
  end

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

  # dilute stocks of samples with ids. e.g. dilute primer stock of primer to primer aliquot, return the diluted stocks to be released in the protocol
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
        check "Grab #{template_stocks.length} 1.5 mL tubes, label them with #{template_diluted_stocks.join(", ")}"
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

  # pass primer ids here and figure out which primer needs to dilute, return the primer ids that needs to be diluted.
  def primers_need_to_dilute ids
    ids = [ids] unless ids.is_a? Array
    dilute_sample_ids = ids.select do |id|
      primer = find(:sample, id: id)[0]
      primer.in("Primer Stock").any? && primer.in("Primer Aliquot").empty?
    end
    return dilute_sample_ids
  end

  def fragment_info fid, p={}

    # This method returns information about the ingredients needed to make the fragment with id fid.
    # It returns a hash containing a list of stocks of the fragment, length of the fragment, as well item numbers for forward, reverse primers and plasmid template (1 ng/µL Plasmid Stock). It also computes the annealing temperature.

    # find the fragment and get its properties
    params = ({ item_choice: false, task_id: nil, check_mode: false }).merge p

    if params[:task_id]
      task = find(:task, id: params[:task_id])[0]
    end

    fragment = find(:sample,{id: fid})[0]
    if fragment == nil
      task.notify "Fragment #{fid} is not in the database.", job_id: jid if task
      return nil
    end
    props = fragment.properties

    # get sample ids for primers and template
    fwd = props["Forward Primer"]
    rev = props["Reverse Primer"]
    template = props["Template"]

    # get length for each fragment
    length = props["Length"]

    if fwd == nil
      task.notify "Forward Primer for fragment #{fid} required", job_id: jid if task
    end

    if rev == nil
      task.notify "Reverse Primer for fragment #{fid} required", job_id: jid if task
    end

    if template == nil
      task.notify "Template for fragment #{fid} required", job_id: jid if task
    end

    if length == nil
      task.notify "Length for fragment #{fid} required", job_id: jid if task
    end


    if fwd == nil || rev == nil || template == nil || length == 0

      return nil # Whoever entered this fragment didn't provide enough information on how to make it

    else

      if fwd.properties["T Anneal"] == nil || fwd.properties["T Anneal"] < 50
        task.notify "T Anneal (higher than 50) for primer #{fwd.id} of fragment #{fid} required", job_id: jid if task
      end

      if rev.properties["T Anneal"] == nil || rev.properties["T Anneal"] < 50
        task.notify "T Anneal (higher than 50) for primer #{rev.id} of fragment #{fid} required", job_id: jid if task
      end

      if fwd.properties["T Anneal"] == nil || fwd.properties["T Anneal"] < 50 || rev.properties["T Anneal"] == nil || rev.properties["T Anneal"] < 50
        return nil
      end

      # get items associated with primers and template
      fwd_items = fwd.in "Primer Aliquot"
      rev_items = rev.in "Primer Aliquot"
      if template.sample_type.name == "Plasmid"
        template_items = template.in "1 ng/µL Plasmid Stock"
        if template_items.length == 0 && template.in("Plasmid Stock").length == 0
          template_items = template.in "Gibson Reaction Result"
        end
      elsif template.sample_type.name == "Fragment"
        template_items = template.in "1 ng/µL Fragment Stock"
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

      if fwd_items.length == 0
        task.notify "Primer aliquot for primer #{fwd.id} of fragment #{fid} required", job_id: jid if task
      end

      if rev_items.length == 0
        task.notify "Primer aliquot for primer #{rev.id} of fragment #{fid} required", job_id: jid if task
      end

      if template_items.length == 0
        task.notify "Stock for template #{template.id} of fragment #{fid} required", job_id: jid if task
      end

      if fwd_items.length == 0 || rev_items.length == 0 || template_items.length == 0

        return nil # There are missing items

      else

        if !params[:check_mode]

          if params[:item_choice]
            fwd_item_to_return = choose_sample fwd_items[0].sample.name, object_type: "Primer Aliquot"
            rev_item_to_return = choose_sample rev_items[0].sample.name, object_type: "Primer Aliquot"
            template_item_to_return = choose_sample template_items[0].sample.name, object_type: template_items[0].object_type.name
          else
            fwd_item_to_return = fwd_items[0]
            rev_item_to_return = rev_items[0]
            template_item_to_return = template_items[0]
          end

          # compute the annealing temperature
          t1 = fwd_items[0].sample.properties["T Anneal"]
          t2 = rev_items[0].sample.properties["T Anneal"]

          # find stocks of this fragment, if any
          #stocks = fragment.items.select { |i| i.object_type.name == "Fragment Stock" && i.location != "deleted"}

          return {
            fragment: fragment,
            #stocks: stocks,
            length: length,
            fwd: fwd_item_to_return,
            rev: rev_item_to_return,
            template: template_item_to_return,
            tanneal: [t1,t2].min
          }

        else

          return true

        end

      end

    end

  end # # # # # # #

  def load_samples_variable_vol headings, ingredients, collections # ingredients must be a string or number

    if block_given?
      user_shows = ShowBlock.new.run(&Proc.new)
    else
      user_shows = []
    end

    raise "Empty collection list" unless collections.length > 0

    heading = [ [ "#{collections[0].object_type.name}", "Location" ] + headings ]
    i = 0

    collections.each do |col|

      tab = []
      m = col.matrix

      (0..m.length-1).each do |r|
        (0..m[r].length-1).each do |c|
          if i < ingredients[0].length
            if m.length == 1
              loc = "#{c+1}"
            else
              loc = "#{r+1},#{c+1}"
            end
            tab.push( [ col.id, loc ] + ingredients.collect { |ing| { content: ing[i], check: true } } )
          end
          i += 1
        end
      end

      show {
          title "Load #{col.object_type.name} #{col.id}"
          table heading + tab
          raw user_shows
        }
    end

  end

end
