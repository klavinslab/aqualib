needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"
needs "aqualib/lib/gradient_pcr"

class Protocol

  include Standard
  include Cloning
  include GradientPCR

  def arguments
    {
      io_hash: {},
      "fragment_ids Fragment" => [2061,2062,4684,4685,4779,4767,4778,13873,13872,13850,13849],
      debug_mode: "Yes",
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", fragment_ids: [], template_stock_ids: [] }.merge io_hash # set default value of io_hash

    # redefine the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # return if no fragments are ready to build
    if io_hash[:fragment_ids].length == 0
      show {
        title "No fragments ready to build"
      }
      io_hash[:stripwell_ids] = []
      return { io_hash: io_hash }
    end
    
    # predict the time needed to finish this protocol based on number of PCRs
    predited_time = time_prediction io_hash[:fragment_ids].length, "PCR"

    # tell the user what we are doing
    show {
      title "Fragment Information"
      note "This protocol will build the following #{io_hash[:fragment_ids].length} fragments:"
      note io_hash[:fragment_ids].join(", ")
      note "The predicted time needed is #{predited_time} min."
    }

    dilute_sample_ids = io_hash[:fragment_ids].collect { |id| fragment_recipe(id)[:dilute_sample_ids] }
    dilute_sample_ids.flatten!
    diluted_stocks = dilute_samples dilute_sample_ids

    # collect fragment pcr information
    fragment_info_list = []
    io_hash[:fragment_ids].each do |fid|
      pcr = fragment_recipe fid
      fragment_info_list.push pcr
    end
    
    # error information
    if io_hash[:template_stock_ids].length > 0
      raise "Incorrect inputs, template_stock_ids size does not match fragment_ids size. They need to be one to one correspondence." if io_hash[:fragment_ids].length != io_hash[:template_stock_ids].length
      fragment_info_list.each_with_index do |fi, idx|
        fi[:template] = find(:item, { id: io_hash[:template_stock_ids][idx] })[0]
      end
    end
    
    # batch fragments, templates, primers
    all_fragments       = fragment_info_list.collect { |fi| fi[:fragment] }
    all_templates       = fragment_info_list.collect { |fi| fi[:template] }
    all_forward_primers = fragment_info_list.collect { |fi| fi[:fwd] }.compact
    all_reverse_primers = fragment_info_list.collect { |fi| fi[:rev] }.compact
    all_primer_ids      = fragment_info_list.collect { |fi| [fi[:fwd_id], fi[:rev_id]] }.flatten

    kapa_stock_item =  find(:sample, name: "Kapa HF Master Mix")[0].in("Enzyme Stock")[0]

    take all_templates + all_forward_primers + all_reverse_primers + [kapa_stock_item] - diluted_stocks, interactive: true,  method: "boxes"

    # Dilute from primer stocks when there isn't enough volume in the existing aliquot or no aliquot exists
    primer_aliquots = all_forward_primers + all_reverse_primers
    enough_vol_primer_aliquots, not_enough_vol_primer_aliquots, contaminated_primer_aliquots, 
    enough_vol_primer_aliquot_bools = determine_enough_volumes_each_item primer_aliquots, primer_aliquots.collect { |p| 2.5 }, check_contam: true
    if contaminated_primer_aliquots.any?
      show {
        title "Discard contaminated primer aliquots"
        note "Discard the following primer aliquots:"
        note contaminated_primer_aliquots.uniq.map { |p| "#{p}" }.join(", ")
      }
      delete contaminated_primer_aliquots
    end
    additional_primer_aliquots = (dilute_samples ((not_enough_vol_primer_aliquots + contaminated_primer_aliquots).map { |p| p.sample.id } + 
      primers_need_to_dilute(all_primer_ids)))

    # build a pcrs hash that group pcr by T Anneal
    pcrs = distribute_pcrs fragment_info_list, 4

    pcrs.each do |pcr|
      lengths = pcr[:fragment_info].values.flatten.collect { |fi| fi[:length] }
      extension_time = (lengths.max)/1000.0*30
      # adding more extension time for longer size PCR.
      if lengths.max < 2000
        extension_time += 30
      elsif lengths.max < 3000
        extension_time += 60
      else
        extension_time += 90
      end
      extension_time = 3 * 60 if extension_time < 3 * 60
      pcr[:mm], pcr[:ss] = (extension_time.to_i).divmod(60)
      pcr[:mm] = "0#{pcr[:mm]}" if pcr[:mm].between?(0, 9)
      pcr[:ss] = "0#{pcr[:ss]}" if pcr[:ss].between?(0, 9)

      # set up stripwells (one for each temperature bin)
      pcr[:stripwells] = pcr[:fragment_info].map do |t, fis| 
        fragments = fis.map { |fi| fi[:fragment] }
        produce spread fragments, "Stripwell", 1, 12
      end
    end

    stripwells = pcrs.collect { |pcr| pcr[:stripwells] }
    stripwells.flatten!

    stripwell_tab = [["Stripwell", "Wells to pipette"]] +
      stripwells.map { |sw| ["#{sw} (#{sw.num_samples <= 6 ? 6 : 12} wells)", { content: sw.non_empty_string, check: true }] }
    show {
      title "Label and prepare stripwells"
      note "Label stripwells, and pipette 19 µL of molecular grade water into each based on the following table:"
      table stripwell_tab
    }

    # add templates to stripwells
    pcrs.each_with_index do |pcr, idx|
      template_tab = [["Stripwell", "Well", "Template, 1 µL"]]
      pcr[:fragment_info].values.each_with_index do |fis, idx|
        stripwell = pcr[:stripwells][idx].first # TODO support multiple stripwells
        fis.each_with_index { |fi, fi_idx| template_tab.push [stripwell.id, fi_idx + 1, { content: fi[:template].id, check: true }] }
      end

      show {
        title "Load templates for PCR ##{idx + 1}"
        table template_tab
        warning "Use a fresh pipette tip for each transfer.".upcase
      }
    end

    # add primers to stripwells
    primer_aliquot_hash = hash_by_sample primer_aliquots.compact + additional_primer_aliquots - contaminated_primer_aliquots
    pcrs.each_with_index do |pcr, idx|
      primer_tab = [["Stripwell", "Well", "Forward Primer, 2.5 µL", "Reverse Primer, 2.5 µL"]]
      pcr[:fragment_info].values.each_with_index do |fis, idx|
        fwd_primer_aliquots_joined = fis.map { |fi| primer_aliquot_hash[fi[:fwd_id]].uniq.map { |p| p.id.to_s }.join(" or ") }
        rev_primer_aliquots_joined = fis.map { |fi| primer_aliquot_hash[fi[:rev_id]].uniq.map { |p| p.id.to_s }.join(" or ") }
        stripwell = pcr[:stripwells][idx].first # TODO support multiple stripwells
        fis.each_with_index do |fi, fi_idx| 
          primer_tab.push [
            stripwell.id, 
            fi_idx + 1, 
            { content: fwd_primer_aliquots_joined[fi_idx], check: true }, 
            { content: rev_primer_aliquots_joined[fi_idx], check: true }
          ]
        end
      end

      show {
        title "Load primers for PCR ##{idx + 1}"
        table primer_tab
        warning "Use a fresh pipette tip for each transfer.".upcase
      }
    end

    # add kapa master mix
    show {
      title "Add Master Mix"
      note "Pipette 25 µL of master mix (#{kapa_stock_item}) into stripwells based on the following table:"
      table stripwell_tab
      warning "USE A NEW PIPETTE TIP FOR EACH WELL AND PIPETTE UP AND DOWN TO MIX."
      check "Cap each stripwell. Press each one very hard to make sure it is sealed."
    }

    if not_enough_vol_primer_aliquots.any?
      show {
        title "Discard depleted primer aliquots"
        note "Discard the following primer aliquots:"
        note not_enough_vol_primer_aliquots.uniq.map { |p| "#{p}" }.join(", ")
      }
      delete not_enough_vol_primer_aliquots
    end

    # run the thermocycler
    pcrs.each_with_index do |pcr, idx|
      is_gradient = pcr[:bins].length > 1
      thermocycler = show {
        if !is_gradient
          title "Start PCR ##{idx + 1} at #{pcr[:bins].first} C"
          check "Place the stripwell(s) #{pcr[:stripwells].first.collect { |sw| "#{sw}" }.join(", ")} into an available thermal cycler and close the lid."
          get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
          check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'CLONEPCR'."
          check "Set the anneal temperature to #{pcr[:bins].first}. This is the 3rd temperature."
        else
          title "Start PCR ##{idx + 1} (gradient) over range #{pcr[:bins].first}-#{pcr[:bins].last} C"
          check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'CLONEPCR'."
          check "Click on annealing temperature -> options, and check the gradient checkbox."
          check "Set the annealing temperature range to be #{pcr[:bins].first}-#{pcr[:bins].last} C."
          note "The following stripwells are ordered front to back."
          pcr[:stripwells].map.with_index do |sws, idx|
            sw = sws.first
            temp = pcr[:fragment_info].keys[idx].to_f
            row_num = pcr[:bins].index temp
            row_letter = ('H'.ord - row_num).chr
            row_letter = 'A' if pcr[:bins].length == 2 && idx == 1
            check "Place the stripwell #{sw} into Row #{row_letter} (#{temp} C) of an available thermal cycler."
          end
          get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
        end
        check "Set the 4th time (extension time) to be #{pcr[:mm]}:#{pcr[:ss]}."
        check "Press 'Run' and select 50 µL."
      }
      # set the location of the stripwell
      pcr[:stripwells].flatten.each do |sw|
        sw.move thermocycler[:name]
      end
    end

    release stripwells
    release all_templates + all_forward_primers + all_reverse_primers + additional_primer_aliquots + [kapa_stock_item], interactive: true, method: "boxes"
    
    # change task status
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"pcr")
      end
    end
    
    # adding stripwell_ids to io_hash and return
    io_hash[:stripwell_ids] = stripwells.collect { |s| s.id }
    return { io_hash: io_hash }

  end

end
