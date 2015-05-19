needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the gibson result ids as a list
      "gibson_result_ids Gibson Reaction Result" => [2853,2853,2853],
      debug_mode: "No",
      inducer_plate: "IPTG",
      cell_type: "DH5alpha"
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    gibson_results = io_hash[:gibson_result_ids].collect{ |gid| find(:item,{id: gid})[0] }
    take gibson_results, interactive: true, method: "boxes"

    io_hash[:cell_type] = "DH5alpha" if !io_hash[:cell_type] || io_hash[:cell_type] == ""

    show {
      title "Initialize the electroporator"
      note "If the electroporator is off (no numbers displayed), turn it on using the ON/STDBY button."
      note "Set the voltage to 1250V by clicking up and down button."
      note " Click the time constant button to show 0.0."
      image "initialize_electroporator"
    }

    transformed_aliquots = gibson_results.collect {|g| produce new_sample g.sample.name, of: "Plasmid", as: "Transformed E. coli Aliquot"}
    ids = transformed_aliquots.collect {|t| t.id}
    num = transformed_aliquots.length
    num_arr = *(1..num)

    show {
      title "Prepare #{num} 1.5 mL tubes and pipettors"
      check "Retrieve and label #{num} 1.5 mL tubes with the following ids #{ids}."
      check "Set your 3 pipettors to be 2 µL, 42 µL, and 1000 µL."
      check "Prepare 10 µL, 100 µL, and 1000 µL pipette tips."
    }

    show {
      title "Retrieve and arrange an ice block"
      note "Retrieve a styrofoam ice block and an aluminum tube rack.\nPut the aluminum tube rack on top of the ice block."
      image "arrange_cold_block"
    }

    show {
      title "Retrieve cuvettes and electrocompetent aliquots"
      check "Retrieve #{num} cuvettes and put inside the styrofoam touching ice block."
      check "Retrieve #{num} #{io_hash[:cell_type]} electrocompetent aliquots from M80 and place on the aluminum tube rack."
      image "handle_electrocompetent_cells"
    }

    show {
      title "Label electrocompetent aliquots"
      check "Label each electrocompetent aliquot with #{num_arr}."
      note "If still frozen, wait till the cells have thawed to a slushy consistency."
      warning "Transformation efficiency depends on keeping electrocompetent cells ice-cold until electroporation."
      warning "Do not wait too long"
      image "thawed_electrocompotent_cells"
    }

    show {
      title "Pipette plasmid into electrocompetent aliquot"
      note "Pipette plasmid/gibson result into labeled electrocompetent aliquot, swirl the tip to mix and place back on the aluminum rack after mixing."
      table [["Plasmid/Gibson Result, 2 µL", "Electrocompetent aliquot"]].concat(gibson_results.collect {|g| { content: g.id, check: true }}.zip num_arr)
      image "pipette_plasmid_into_electrocompotent_cells"
    }

    show {
      title "Electroporation and Rescue"
      check "Grab a 50 mL LB liquid aliquot (sterile) and loosen the cap."
      check "Take a labeled electrocompetent aliquot. Using the set 100uL pipette, transfer the mixture into the center of an electrocuvette, slide into electroporator and press the PULSE button twice quickly."
      check "Remove the cuvette from the electroporator and QUICKLY add 1 mL of LB."
      check "Pipette up and down 3 times to extract the cells from the gap in the cuvette, then, using the set 1000uL pipette, transfer to a labeled 1.5 mL tube according to the following table. Repeat for the rest electrocompetent aliquots."
      table [["Electrocompetent aliquot", "1.5 mL tube label"]].concat(num_arr.zip ids.collect {|i| { content: i, check: true }})
    }

    show {
      title "Clean up"
      check "Put all cuvettes into washing station."
      check "Discard empty electrocompetent aliquot tubes into waste bin."
      check "Return the styrofoam ice block and the aluminum tube rack."
      image "dump_dirty_cuvettes"
    }

    show {
      title "Incubate the following 1.5 mL tubes"
      check "Put the tubes with the following ids into 37 C incubator using the small green tube holder."
      note "Retrieve all the tubes 30 minutes later by doing the following plate_ecoli_transformation protocol. You can finish this protocol now by perfoming the next return steps."
      note "#{transformed_aliquots.collect {|t| t.id}}"
      image "put_green_tube_holder_to_incubator"
    }

    move transformed_aliquots, "37 C incubator"
    release transformed_aliquots

    gibson_results.each do |g|
      g.store
      g.reload
    end

    release gibson_results, interactive: true, method: "boxes"
    io_hash[:transformed_aliquots_ids] = transformed_aliquots.collect { |t| t.id }

    # Set tasks in the io_hash to be transformed
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"transformed")
      end
    end
    return { io_hash: io_hash }

  end #main

end #Protocol
