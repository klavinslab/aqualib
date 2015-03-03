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
      item_choice_mode: "No",
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", item_choice_mode: "No" }.merge io_hash # set default value of io_hash

    # redefine the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # collect fragment pcr
    fragment_info_list = []
    not_ready = []

    io_hash[:fragment_ids].each do |fid|
      if io_hash[:item_choice_mode].downcase == "yes"
        pcr = fragment_info fid, item_choice: true
      else
        pcr = fragment_info fid
      end
      fragment_info_list.push pcr   if pcr
      not_ready.push fid if !pcr
    end

    all_fragments       = fragment_info_list.collect { |fi| fi[:fragment] }
    all_templates       = fragment_info_list.collect { |fi| fi[:template] }
    all_forward_primers = fragment_info_list.collect { |fi| fi[:fwd] }
    all_reverse_primers = fragment_info_list.collect { |fi| fi[:rev] }

    # return if no fragments are ready to build
    if all_fragments.length == 0
      show {
        title "No fragments ready to build"
      }
      io_hash[:stripwell_ids] = []
      return { io_hash: io_hash }
    end

    # tell the user what we are doing
    show {
      title "Fragment Information"
      note "This protocol will build the following fragments:"
      note (all_fragments.collect { |f| "#{f.id}" })
      if not_ready.length > 0
        separator
        note "The following fragments have missing ingredients and will not be built:"
        note not_ready.to_s
      end
    }

    # take the primers and templates
    take all_templates + all_forward_primers + all_reverse_primers, interactive: true,  method: "boxes"

    # get phusion enzyme
    phusion_stock_item = choose_sample "Phusion HF Master Mix"
    take [phusion_stock_item], interactive: true, method: "boxes" 

    # build a pcrs hash that group fragment pcr by T Anneal
    pcrs = Hash.new { |h, k| h[k] = { fragment_info: [], mm: 0, ss: 0, fragments: [], templates: [], forward_primers: [], reverse_primers: [], stripwells: [] } }

    fragment_info_list.each do |fi|
      if fi[:tanneal] >= 70
        pcrs[70][:fragment_info].push fi
      elsif fi[:tanneal] >= 67
        pcrs[67][:fragment_info].push fi
      else
        pcrs[64][:fragment_info].push fi
      end
    end

    pcrs.each do |t, pcr|
      lengths = pcr[:fragment_info].collect { |fi| fi[:length] }
      extension_time = (lengths.max)/1000.0*30 + 30
      pcr[:mm], pcr[:ss] = (extension_time.to_i).divmod(60)

      pcr[:fragments].concat pcr[:fragment_info].collect { |fi| fi[:fragment] }
      pcr[:templates].concat pcr[:fragment_info].collect { |fi| fi[:template] }
      pcr[:forward_primers].concat pcr[:fragment_info].collect { |fi| fi[:fwd] }
      pcr[:reverse_primers].concat pcr[:fragment_info].collect { |fi| fi[:rev] }

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

    # add phusion enzyme
    show {
      title "Add Master Mix"
      stripwells.each do |sw|
        check "Pipette 25 µL of master mix (item #{phusion_stock_item}) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
      end
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      note ""
      warning "USE A NEW PIPETTE TIP FOR EACH WELL AND PIPETTE UP AND DOWN TO MIX"
    }

    # run the thermocycler
    pcrs.each do |t, pcr|
      thermocycler = show {
        title "Start the PCRs at #{t} C"
        check "Place the stripwells #{pcr[:stripwells].collect { |sw| sw.id } } into an available thermal cycler and close the lid."
        get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
        separator
        check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'CLONEPCR'."
        check "Set the anneal temperature to #{t.round(0)}. This is the 3rd temperature."
        check "Set the 4th time (extension time) to be #{pcr[:mm]}:#{pcr[:ss]}."
        check "Press 'run' and select 50 µL."
        #image "thermal_cycler_select"
      }
      pcr[:stripwells].each do |sw|
        sw.move thermocycler[:name]
      end
    end

    # set the location of the stripwells to be the name of the thermocycler, release silently
    release stripwells

    # release phusion enzyme
    release [ phusion_stock_item ], interactive: true, method: "boxes"

    # release the templates, primers
    release all_templates + all_forward_primers + all_reverse_primers , interactive: true, method: "boxes" 
    
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"pcr")
      end
    end

    io_hash[:stripwell_ids] = stripwells.collect { |s| s.id }

    return { io_hash: io_hash }

  end

end
