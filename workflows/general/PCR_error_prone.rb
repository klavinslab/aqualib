needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the fragment sample id (not item ids) as a list, eg [2048,2049,2060,2061,2,2]
      fragment_ids: [2049,2062],
      #Enter expected number of mutations on this fragment
      mutation_nums: [2,4],
      debug_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No" }.merge io_hash
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # Collect fragment info
    fragment_info_list = []
    not_ready = []
    io_hash[:comb_1] = "6 thick"
    io_hash[:comb_2] = "0"

    # making sure have the following hash indexes.
    io_hash = { fragment_ids: [], mutation_nums: [] }.merge io_hash
    tasks = find(:task,{ task_prototype: { name: "Mutagenized Fragment Construction" } })
    ready_ids = (tasks.select { |t| t.status == "ready" }).collect { |t| t.id }
    io_hash[:task_ids] = ready_ids

    show {
      note "#{io_hash}"
    }

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      io_hash[:fragment_ids].concat task.simple_spec[:fragments]
      io_hash[:mutation_nums].concat task.simple_spec[:mutation_nums]
    end

    mutation_nums = io_hash[:mutation_nums]

    fragments        = io_hash[:fragment_ids].collect { |fid| find(:sample, id: fid)[0]}
    lengths          = fragments.collect { |f| f.properties["Length"]}
    templates        = fragments.collect { |f| f.properties["Template"].in("Plasmid Stock")[0]}
    template_lengths = templates.collect { |tp| tp.sample.properties["Length"] }
    concs            = templates.collect { |tp| tp.datum[:concentration] }
    forward_primers  = fragments.collect { |f| f.properties["Forward Primer"].in("Primer Aliquot")[0]}
    reverse_primers  = fragments.collect { |f| f.properties["Reverse Primer"].in("Primer Aliquot")[0]}
    temperatures     = fragments.collect { |f| (f.properties["Forward Primer"].properties["T Anneal"] + f.properties["Reverse Primer"].properties["T Anneal"])/2 }

    # find the average annealing temperature
    tanneal = temperatures.inject{ |sum, el| sum + el }.to_f / temperatures.size

    show {
      note fragments.collect { |f| f.id }
    }

    # find the extension time, 30 sec/kb + 30 sec
    extension_time = (lengths.max)/1000.0*30 + 30
    mm, ss = (extension_time.to_i).divmod(60) 

    # find target amount in template for error prone PCR
    mutation_nums_kb = mutation_nums.map.with_index { |m,i| m * 1000.0 / lengths[i] }
    target_amount    = mutation_nums_kb.collect { |n| Math.exp((12.6-n)/1.9) }
    template_amount  = target_amount.map.with_index { |t,i| t * template_lengths[i] / lengths[i]}
    template_volume  = template_amount.map.with_index { |t,i| t / concs[i]}

    # find template vol and id, primer vol and id, water vol to add error prone PCR
    template_id_vol    = templates.map.with_index {|t,i| template_volume[i].round(1).to_s + " µL of " + t.id.to_s}
    water_vol           = template_volume.collect {|v| (42.5 - v).round(1).to_s + " µL"}
    forward_primers_vol = forward_primers.map.with_index {|f| "0.25 µL of " + f.id.to_s}
    reverse_primers_vol = reverse_primers.map.with_index {|f| "0.25 µL of " + f.id.to_s}

    # Tell the user what we are doing
    show {
      title "Fragment Information"
      note "This protocol will build the following fragments with expected input mutation numbers:"
      note (fragments.map.with_index { |f,i| " #{f} with #{mutation_nums[i]} bp mutations" })
      note ("The amount in ng for each template needed to be add are:" )
      note (template_amount.collect { |t| "#{t.round(2)}"  })
      #note (net_length.collect { |l| "#{l}"})
      #note (template_length.collect { |l| "#{l}"})
      #note (props.collect {|p| "#{p}"})
      #note (template_volume.collect {|c| "#{c.round(2)}"})
      if not_ready.any?
        separator
        note "The following fragments have missing ingredients and will not be built:"
        note not_ready.collect { |f| " #{f}"}
      end
    }

    # Take the primers and templates
    take templates + forward_primers + reverse_primers, interactive: true,  method: "boxes"

    # Centrifuge all the template and primers
    template_and_primers = (templates + forward_primers + reverse_primers).uniq{|x| x}

    show {
      title "Quick centrifuge templates and primers"
      note "Put the following items in a table top centrifuge (make sure to balance) and spin for 5 seconds."
      note (template_and_primers.collect { |t| "#{t.id}"  })
    }

    # Get Mutazyme and buffers
    buffer_stock_item = choose_sample "10X Mutazyme II reaction buffer", take: false
    dNTP_stock_item = choose_sample "40 mM dNTP mix", take: false
    mutazymeII_stock_item = choose_sample "Mutazyme II DNA polymerase", take: false

    take([buffer_stock_item] + [dNTP_stock_item] + [mutazymeII_stock_item], interactive: true, method: "boxes") {
        warning "Use an Ice Block to retrieve all the items!"
    }

    # Set up stripwells
    stripwells = produce spread fragments, "Stripwell", 1, 12

    show {
      title "Prepare Stripwell Tubes"
      stripwells.each do |sw|
        check "Label a new stripwell with the id #{sw}. Grab 5 wells for less than 5 reactions."
        separator
      end
      # TODO: Put an image of a labeled stripwell here
    }

    # Set up reactions
    load_samples_variable_vol( [ "Molecular Grade Water","Template", "Forward Primer", "Reverse Primer"], [
        water_vol,
        template_id_vol,
        forward_primers_vol,
        reverse_primers_vol
      ], stripwells ) {
        note "Load templates first, then forward primers, then reverse primers."
        warning "Use a fresh pipette tip for each transfer."
      }

    show {
      title "Add Buffer, dNTPs and Mutazyme II"
      stripwells.each do |sw|
        check "Pipette 5 µL of 10X Mutazyme II Buffer (item #{buffer_stock_item}) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
        check "Pipette 1 µL of 40 mM dNTP mix (item #{dNTP_stock_item}) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
        check "Pipette 1 µL of Mutazyme II DNA polymerase (item #{mutazymeII_stock_item}) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
      end
      separator
      warning "Use a new pipette tip for each pipetting! Pipette up and down to mix."
    }


    # Run the thermocycler
    thermocycler = show {
      title "Start the reactions"
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      separator
      check "Place the stripwells into an available thermal cycler and close the lid."
      get "text", var: "name", label: "Enter the name of the thermocycler used", default: "T1"
      separator
      check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'ERRORPCR'."
      check "Set the anneal temperature to #{tanneal.round(0)-5}. This is the 3rd temperature."
      check "Set the 4th time (extension time) to be #{mm}:#{ss}."
      check "Press 'run' and select 50 µL."
      # TODO: image: "thermal_cycler_home"
    }

    # Set the location of the stripwells to be the name of the thermocycler
    stripwells.each do |sw|
      sw.move thermocycler[:name]
    end

    # Release the templates, primers, and enzymes
    release templates + forward_primers + reverse_primers + [ buffer_stock_item ] + [dNTP_stock_item] + [mutazymeII_stock_item], interactive: true, method: "boxes" 

    # Release the stripwells silently, since they should stay in the thermocycler
    release stripwells

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












