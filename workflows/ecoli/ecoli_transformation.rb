needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the gibson result ids as a list
      "gibson_result_ids Gibson Reaction Result" => [2853,3002,3003,3004],
      plasmid_item_ids: [],
      debug_mode: "No",
      inducer_plate: "IPTG",
      cell_type: "DH5alpha"
    }
  end #arguments



  def find_batch(plasmid_items)
  	ecoli_batch = find(:item, object_type: { name: "E. coli Comp Cell Batch" }).sort { |batch1, batch2| batch1.id <=> batch2.id }
  	ecoli_batch.each do |item|
  	  
  	  # for debugging
  	  #show {
  	  # note item.id
  	  # note item.get("tested")
  	  # note plasmid_items.length
  	  # note plasmid_items[0].sample.name
  	  # note plasmid_items[1].sample.name
  	  # note Collection.find(item.id).num_samples
  	  # note Collection.find(item.id).dimensions
  	  #}
  	  
  	  # bug where (plasmid_items.length == 1 &&) does not hold true when only one is inserted 
  	  if plasmid_items[0].sample.name == "SSJ128" && item.get("tested") == "No"
  	    return item
  	  elsif plasmid_items[0].sample.name != "SSJ128" && item.get("tested") == "Yes"
  	    return item
  	  end
    end
    return nil
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "Yes", gibson_result_ids: [], plasmid_item_ids: [], task_ids: [], ecoli_transformation_task_ids: [], group: "technicians"}.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    ecoli_transformation_tasks_list = find_tasks task_prototype_name: "Ecoli Transformation", group: io_hash[:group]
    ecoli_transformation_tasks = task_status ecoli_transformation_tasks_list
    io_hash[:ecoli_transformation_task_ids] = task_choose_limit(ecoli_transformation_tasks[:ready_ids], "Ecoli Transformation")
    io_hash[:ecoli_transformation_task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      io_hash[:plasmid_item_ids].concat task.simple_spec[:plasmid_item_ids]
    end
    gibson_results = io_hash[:gibson_result_ids].collect{ |gid| find(:item,{id: gid})[0] }
    plasmid_items = io_hash[:plasmid_item_ids].collect { |id| find(:item,{ id: id })[0] }
    items_to_transform = gibson_results + plasmid_items
    take items_to_transform, interactive: true, method: "boxes"

    io_hash[:cell_type] = "DH5alpha" if !io_hash[:cell_type] || io_hash[:cell_type] == ""

        transformed_aliquots = items_to_transform.collect {|g| produce new_sample g.sample.name, of: "Plasmid", as: "Transformed E. coli Aliquot"}
    transformed_aliquots.each_with_index do |transformed_aliquot,idx|
      transformed_aliquot.datum = transformed_aliquot.datum.merge({ from: items_to_transform[idx].id })
    end
    ids = transformed_aliquots.collect {|t| t.id}
    num = transformed_aliquots.length
    num_arr = *(1..num)

    # TODO: Fix e. coli batching so it doesn't reference plasmid_items[0] when nil
    if plasmid_items.length != 0
      ecolibatch = find_batch(plasmid_items)
      if ecolibatch.nil?
        #raise "No such E coli batch"
      elsif ecolibatch.get("tested") == "No"
        Item.find(ecolibatch.id).associate "tested", "Yes", upload=nil
        matrix = Collection.find(ecolibatch).matrix
        num_samp = Collection.find(ecolibatch).num_samples
        row = num_samp / (matrix[0].length)
        col = (num_samp - 1) % matrix[0].length    
        # for debugging
        #show {
        #  note row
        #  note col
        #}
        Collection.find(ecolibatch).set row, col, nil
      end
    end

    show {
      title "Prepare bench"
      note "If the electroporator is off (no numbers displayed), turn it on using the ON/STDBY button."
      note "Set the voltage to 1250V by clicking up and down button."
      note " Click the time constant button to show 0.0."
      image "initialize_electroporator"
      check "Retrieve and label #{num} 1.5 mL tubes with the following ids #{ids}."
      check "Set your 3 pipettors to be 2 µL, 42 µL, and 900 µL."
      check "Prepare 10 µL, 100 µL, and 1000 µL pipette tips."      
      check "Grab a Bench  liquid aliquot (sterile) and loosen the cap."
    }

    show {
      title "Get cold items"
      note "Retrieve a styrofoam ice block and an aluminum tube rack.\nPut the aluminum tube rack on top of the ice block."
      image "arrange_cold_block"
      check "Retrieve #{num} cuvettes and put inside the styrofoam touching ice block."
      check "Retrieve #{num} #{io_hash[:cell_type]} electrocompetent aliquots from M80 and place on the aluminum tube rack."
      image "handle_electrocompetent_cells"
    }

    show {
      title "Label aliquots"
      check "Label each electrocompetent aliquot with #{num_arr}."
      note "If still frozen, wait till the cells have thawed to a slushy consistency."
      warning "Transformation efficiency depends on keeping electrocompetent cells ice-cold until electroporation."
      warning "Do not wait too long"
      image "thawed_electrocompotent_cells"
    }

    show {
      title "Add plasmid to electrocompetent aliquot, electroporate and rescue "
      note "Repeat for each row in the table:"
      check "Pipette 2 uL plasmid/gibson result into labeled electrocompetent aliquot, swirl the tip to mix and place back on the aluminum rack after mixing."
      check "Transfer 42 uL of e-comp cells to electrocuvette with P100"
      check "Slide into electroporator, press PULSE button twice, and QUICKLY add 900 uL of SOC"
      check "pipette cells up and down 3 times, then transfer 900 uL to appropriate 1.5 mL tube with P1000"
      #table [["Plasmid/Gibson Result, 2 µL", "Electrocompetent aliquot"]].concat(items_to_transform.collect {|g| { content: g.id, check: true }}.zip num_arr)
      table [["Plasmid/Gibson Result, 2 µL", "Electrocompetent aliquot", "1.5 mL tube label"]].concat(items_to_transform.collect {|g| { content: g.id, check: true }}.zip(num_arr, ids.collect {|i| { content: i, check: true}}))
      image "pipette_plasmid_into_electrocompotent_cells"
      #check "Take a labeled electrocompetent aliquot. Using the set 100uL pipette, transfer the mixture into the center of an electrocuvette, slide into electroporator and press the PULSE button twice quickly."
      #check "Remove the cuvette from the electroporator and QUICKLY add 300 µL of SOC."
      #check "Pipette up and down 3 times to extract the cells from the gap in the cuvette, then, using the set 1000uL pipette, transfer to a labeled 1.5 mL tube according to the following table. Repeat for the rest electrocompetent aliquots."
      #table [["Electrocompetent aliquot", "1.5 mL tube label"]].concat(num_arr.zip ids.collect {|i| { content: i, check: true }}) 
    } 
    
    amp = 0
    kan = 0
    items_to_transform.each do |item|
      if item.sample.properties["Bacterial Marker"] == "Amp"
        amp += 1
      elsif item.sample.properties["Bacterial Marker"] == "Kan"
        kan += 1
      end
    end

    show {
      title "Incubate tubes"
      check   "Find an empty, sterile (autoclaved) 250 mL flask."
      check   "Remove the foil and carefully drop all transformed aliquots in 1.5 mL tubes into the flask."
      warning "Make sure the caps are closed tightly on the 1.5 mL tubes!"
      check "Move the 250 mL flask containing the transformed aliquots to an empty 250 mL flask holder in the 37 shaker/incubator."
      note "#{transformed_aliquots.collect {|t| t.id}}"
      note "Place #{amp} Amp plates and #{kan} Kan plates into the incubator"
      image "37_c_shaker_incubator"
    }

    show {
      title "Clean up"
      check "Put all cuvettes into washing station."
      check "Discard empty electrocompetent aliquot tubes into waste bin."
      check "Return the styrofoam ice block and the aluminum tube rack."
      image "dump_dirty_cuvettes"
    }
    
    move transformed_aliquots, "37 C shaker/incubator"
    release transformed_aliquots

    gibson_results.each do |g|
      g.store
      g.reload
    end

    release items_to_transform, interactive: true, method: "boxes"
    io_hash[:transformed_aliquots_ids] = transformed_aliquots.collect { |t| t.id }

    # Set tasks in the io_hash to be transformed
    io_hash[:task_ids].concat io_hash[:ecoli_transformation_task_ids]
    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"transformed")
    end
    return { io_hash: io_hash }

  end #main

end #Protocol
