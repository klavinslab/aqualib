needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "fragment_ids Fragment" => [2061,2062,4684,4685,4779,4767,4778],
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
    all_forward_primers = fragment_info_list.collect { |fi| fi[:fwd] }
    all_reverse_primers = fragment_info_list.collect { |fi| fi[:rev] }

    kapa_stock_item =  find(:sample, name: "Kapa HF Master Mix")[0].in("Enzyme Stock")[0]
    take all_templates + all_forward_primers + all_reverse_primers - diluted_stocks + kapa_stock_item, interactive: true,  method: "boxes"

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
    additional_primer_aliquots = (dilute_samples ((not_enough_vol_primer_aliquots + contaminated_primer_aliquots).map { |p| p.sample.id } + primers_need_to_dilute(primer_ids)))

    # build a pcrs hash that group pcr by T Anneal
    pcrs = Hash.new { |h, k| h[k] = { fragment_info: [], mm: 0, ss: 0, fragments: [], templates: [], forward_primers: [], reverse_primers: [], stripwells: [], tanneals: [] } }

    fragment_info_list.each do |fi|
      if fi[:tanneal] >= 70
        key = :t70
      elsif fi[:tanneal] >= 67
        key = :t67
      elsif fi[:tanneal] >= 64
        key = :t64
      else
        key = :t60
      end
      pcrs[key][:fragment_info].push fi
    end

    pcrs.each do |t, pcr|
      lengths = pcr[:fragment_info].collect { |fi| fi[:length] }
      extension_time = (lengths.max)/1000.0*30
      # adding more extension time for longer size PCR.
      if lengths.max < 2000
        extension_time += 30
      elsif lengths.max < 3000
        extension_time += 60
      else
        extension_time += 90
      end
      pcr[:mm], pcr[:ss] = (extension_time.to_i).divmod(60)
      pcr[:mm] = "0#{pcr[:mm]}" if pcr[:mm].between?(0, 9)
      pcr[:ss] = "0#{pcr[:ss]}" if pcr[:ss].between?(0, 9)

      pcr[:fragments].concat pcr[:fragment_info].collect { |fi| fi[:fragment] }
      pcr[:templates].concat pcr[:fragment_info].collect { |fi| fi[:template] }
      pcr[:forward_primers].concat pcr[:fragment_info].collect { |fi| fi[:fwd] }
      pcr[:reverse_primers].concat pcr[:fragment_info].collect { |fi| fi[:rev] }
      pcr[:tanneals].concat pcr[:fragment_info].collect { |fi| fi[:tanneal] }

      # set up stripwells
      pcr[:stripwells] = produce spread pcr[:fragments], "Stripwell", 1, 12

    end

    stripwells = pcrs.collect { |t, pcr| pcr[:stripwells] }
    stripwells.flatten!

    show {
      title "Prepare Stripwell Tubes"
      stripwells.each do |sw|
        if sw.num_samples <= 6
          check "Grab a new stripwell with 6 wells and label with the id #{sw}."
        else
          check "Grab a new stripwell with 12 wells and label with the id #{sw}."
        end
        note "Pipette 19 µL of molecular grade water into wells " + sw.non_empty_string + "."
      end
      # TODO: Put an image of a labeled stripwell here
    }

    # add templates to stripwells
    pcrs.each do |t, pcr|
      load_samples( [ "Template, 1 µL"], [
          pcr[:templates]
        ], pcr[:stripwells] ) {
          warning "Use a fresh pipette tip for each transfer.".upcase
        }
    end

    # add primers to stripwells
    pcrs.each do |t, pcr|
      load_samples( [ "Forward Primer, 2.5 µL", "Reverse Primer, 2.5 µL" ], [
          pcr[:forward_primers],
          pcr[:reverse_primers]
        ], pcr[:stripwells] ) {
          warning "Use a fresh pipette tip for each transfer.".upcase
        }
    end

    # add kapa master mix
    show {
      title "Add Master Mix"
      warning "USE A NEW PIPETTE TIP FOR EACH WELL AND PIPETTE UP AND DOWN TO MIX"
      stripwells.each do |sw|
        check "Pipette 25 µL of master mix (item #{kapa_stock_item}) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
      end
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
    }

    if not_enough_vol_primer_aliquots.any?
      show {
        title "Discard depleted primer aliquots"
        note "Discard the following primer aliquots:"
        note not_enough_vol_primer_aliquots.uniq.map { |p| "#{p}" }.join(", ")
      }
      ##############################delete not_enough_vol_primer_aliquots
    end

    # run the thermocycler
    pcrs.each do |key, pcr|
      tanneal = pcr[:tanneals].min.round(0)
      thermocycler = show {
        title "Start the PCRs at #{tanneal} C"
        check "Place the stripwells #{pcr[:stripwells].collect { |sw| sw.id } } into an available thermal cycler and close the lid."
        get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
        separator
        check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'CLONEPCR'."
        check "Set the anneal temperature to #{tanneal}. This is the 3rd temperature."
        check "Set the 4th time (extension time) to be #{pcr[:mm]}:#{pcr[:ss]}."
        check "Press 'Run' and select 50 µL."
        #image "thermal_cycler_select"
      }
      # set the location of the stripwell
      pcr[:stripwells].each do |sw|
        sw.move thermocycler[:name]
      end
    end

    release stripwells
    release all_templates + all_forward_primers + all_reverse_primers + additional_primer_aliquots + kapa_stock_item, interactive: true, method: "boxes"
    
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
