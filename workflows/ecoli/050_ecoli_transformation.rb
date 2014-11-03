needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the gibson result ids as a list
      "gibson_result_ids Gibson Reaction Result" => [13002,13003,13004,13005,12197],
      debug_mode: "Yes"
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
    gibson_results = io_hash[:gibson_result_ids].collect{|gid| find(:item,{id: gid})[0]}
    # group gibson results into hash by their bacterial marker
    gibson_result_marker_hash = Hash.new {|h,k| h[k] = [] }
    gibson_results.each do |g|
      if g.sample.properties["Bacterial Marker"].downcase[0,3] == "amp"
        gibson_result_marker_hash[:amp].push g
      else
        gibson_result_marker_hash[:non_amp].push g
      end
    end
    take gibson_results, interactive: true, method: "boxes"

    show {
    	title "Intialize the electroporator"
    	note "If the electroporator is off (no numbers displayed), turn it on using the ON/STDBY button."
      note "Turn on the electroporator if it is off and set the voltage to 1250V by clicking up and down button. Click the time constant button."
    }

    transformed_aliquots = []
    plates = []
    gibson_result_marker_hash.each do |marker, gibson_result|
    	num = gibson_result.length
    	num_arr = *(1..num)
    	ids = []
    	if marker == :non_amp
        transformed_aliquots = gibson_result.collect {|g| produce new_sample g.sample.name, of: "Plasmid", as: "Transformed E. coli Aliquot"}
        ids = transformed_aliquots.collect {|t| t.id} 
    	elsif marker == :amp
        plates = gibson_result.collect {|g| produce new_sample g.sample.name, of: "Plasmid", as: "E coli Plate of Plasmid"}
        ids = *(1..num)
      end

      show {
        title "Retrieve and arrange ice block"
        note "Retrieve a styrofoam ice block and an aluminum tube rack.\nPut the aluminum tube rack on top of the ice block."
        image "arrange_cold_block"
      }

      show {
        title "Retrieve cuvettes and electrocompetent aliquots"
        check "Retrieve #{num} cuvettes put all inside the styrofoam touching ice block."
        check "Retrieve #{num} DH5alpha electrocompetent aliquots from M80 and place it on the aluminum tube rack."
        image "handle_electrocompetent_cells"
      }

      show {
        title "Prepare #{num} 1.5 mL tubes and pipetters"
        check "Retrieve and label #{num} 1.5 mL tubes with the following ids #{ids}."
        check "Set your 3 pipettors to be 2 µL, 42 µL, and 1000 µL."
        check "Prepare 10 µL, 100 µL, and 1000 µL pipette tips."
      }

      show {
        title "Label the electrocompetent cell"
        check "Label each electrocompetent aliquot with #{num_arr}."
        note "If still frozen, wait till the cells have thawed to a slushy consistency."
        warning "Transformation efficiency depends on keeping electrocompetent cells ice-cold until electroporation."
        warning "Do not wait too long"
        image "thawed_electrocompotent_cells"
      }

      show {
        title "Pipette plasmid into electrocompetent aliquot"
        note "Pipette plasmid/gibson result into labeled electrocompetent aliquot, swirl the tip to mix and place back on the aluminum rack after mixing."
        table [["Plasmid/Gibson Result, 2 µL", "Electrocompetent aliquot"]].concat(gibson_result.collect {|g| { content: g.id, check: true }}.zip num_arr)
      }

      show {
        title "Electroporation and Rescue"
        check "Grab a 50 mL LB liquid aliquot (sterile) and loosen the cap."
        check "Take a labeled electrocompetent aliquot, transfer mixture into the center of an electrocuvette, slide into electroporator and press the PULSE button twice quickly."
        check "Remove the cuvette from the electroporator and QUICKLY add 1 mL of LB."
        check "Pipette up and down 3 times to extract the cells from the gap in the cuvette, then transfer to a labeled 1.5 mL tube according to the following table. Repeat for the rest electrocompetent aliquots."
        table [["Electrocompetent aliquot", "1.5 mL tube label"]].concat(num_arr.zip ids.collect {|i| { content: i, check: true }})
      }

      show {
        title "Clean up"
        check "Put all cuvettes into washing station."
        check "Discard empty electrocompetent aliquot tubes into waste bin."
        check "Return the styrofoam ice block and the aluminum tube rack."
      }

      if marker == :non_amp
        show {
          title "Incubate the following 1.5 mL tubes"
          check "Put the tubes with the following ids into 30 C incubator using the small green tube holder."
          note "#{transformed_aliquots.collect {|t| t.id}}"
        }
        transformed_aliquots.each do |t|
          t.location = "30 C incubator"
          t.save
        end
        release transformed_aliquots
      end

      if marker == :amp
        num_arr = *(1..plates.length)
        show {
          title "Plate on LB Amp Plate (sterile)"
          check "Grab #{plates.length} LB Amp Plate (sterile) from fridge."
          check "Label the plates with id #{plates.collect {|p| p.id}}."
          check "Use sterile beads to plate 200 µL from each 1.5 mL tube onto a labeled LB Amp Plate according to the following table. Discard the 1.5 mL tube after plating."
          table [["1.5 mL tube","LB Amp Plate"]].concat(num_arr.zip plates.collect{ |p| { content: p.id, check: true } })
        }
        plates.each do |p|
          p.location = "37 C incubator"
          p.save
        end
        release plates, interactive: true, method: "boxes"
      end

    end #gibson_result_marker_hash

    release gibson_results, interactive: true, method: "boxes"

    io_hash[:transformed_aliquots_ids] = transformed_aliquots.collect { |t| t.id }
    io_hash[:plate_ids] = plates.collect { |p| p.id }
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"transformed")
      end
    end
    return { io_hash: io_hash }

  end #main

end #Protocol