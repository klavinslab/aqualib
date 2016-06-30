needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      gibson_result_ids: [14150,14151,14152],
      plasmid_item_ids: [],
      debug_mode: "No",
      inducer_plate: "IPTG",
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "Yes", gibson_result_ids: [], plasmid_item_ids: [], task_ids: [], group: "technicians"}.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    gibson_results = io_hash[:gibson_result_ids].collect{ |gid| find(:item,{id: gid})[0] }
    plasmid_items = io_hash[:plasmid_item_ids].collect { |id| find(:item,{ id: id })[0] }
    items_to_transform = gibson_results + plasmid_items
    take items_to_transform, interactive: true, method: "boxes"

    transformed_aliquots = items_to_transform.collect {|g| produce new_sample g.sample.name, of: "Plasmid", as: "Transformed Agro Aliquot"}
    transformed_aliquots.each_with_index do |transformed_aliquot,idx|
      transformed_aliquot.datum = transformed_aliquot.datum.merge({ from: items_to_transform[idx].id })
    end
    ids = transformed_aliquots.collect {|t| t.id}
    num = transformed_aliquots.length
    num_arr = *(1..num)

    show {
      title "Prepareeeeee bench"
      note "If the electroporator is off (no numbers displayed), turn it on using the ON/STDBY button."
      note "Set the voltage to 1250V by clicking up and down button."
      note " Click the time constant button to show 0.0."
      image "initialize_electroporator"
      check "Retrieve and label #{num} 1.5 mL tubes with the following ids #{ids}."
      check "Set your 3 pipettors to be 2 µL, 42 µL, and 1000 µL."
      check "Prepare 10 µL, 100 µL, and 1000 µL pipette tips."      
      check "Grab a Bench LB liquid aliquot (sterile) and loosen the cap."
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
      title "Pipette plasmid into electrocompetent aliquot"
      note "Pipette plasmid/gibson result into labeled electrocompetent aliquot, swirl the tip to mix and place back on the aluminum rack after mixing."
      table [["Plasmid/Gibson Result, 2 µL", "Electrocompetent aliquot", "1.5 mL tube label"]].concat(items_to_transform.collect {|g| { content: g.id, check: true }}.zip(num_arr, ids.collect {|i| { content: i, check: true}}))
      image "pipette_plasmid_into_electrocompotent_cells"
    }

    show {
      title "Electroporation and Rescue"
      note "Repeat for every Gibson aliquot"
      check "Transfer e-comp cells to electrocuvette with P1000"
      check "Slide into electroporator, press PULSE button twice, and QUICKLY add 350 uL of LB"
      check "pipette cells up and down 3 times, then transfer to appropriate 1.5 mL tube with P1000"
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
      check "Put the tubes with the following ids into 37 C incubator using the small green tube holder."
      note "Retrieve all the tubes 30 minutes later by doing the following plate_agro_transformation protocol. You can finish this protocol now by perfoming the next return steps."
      note "#{transformed_aliquots.collect {|t| t.id}}"
      note "Place #{amp} Amp plates and #{kan} Kan plates into the incubator"
      image "put_green_tube_holder_to_incubator"
    }

    show {
      title "Clean up"
      check "Put all cuvettes into washing station."
      check "Discard empty electrocompetent aliquot tubes into waste bin."
      check "Return the styrofoam ice block and the aluminum tube rack."
      image "dump_dirty_cuvettes"
    }

    move transformed_aliquots, "30 C incubator"
    release transformed_aliquots

    gibson_results.each do |g|
      g.store
      g.reload
    end

    release items_to_transform, interactive: true, method: "boxes"
    io_hash[:transformed_aliquots_ids] = transformed_aliquots.collect { |t| t.id }

    # Set tasks in the io_hash to be transformed
    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"transformed")
    end
    return { io_hash: io_hash }

  end #main

end #Protocol
