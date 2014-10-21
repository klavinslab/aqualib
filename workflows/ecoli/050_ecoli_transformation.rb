needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the gibson result ids as a list
      gibson_result_ids: [13002,13003,13004,13005],
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
    gibson_results.each_with_index do |g|
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

    show {
    	title "Retrieve and arrange ice block"
    	note "Retrieve a styrofoam ice block and an aluminum tube rack.\nPut the aluminum tube rack on top of the ice block."
        image "arrange_cold_block"
    }

    transformed_aliquots = []
    gibson_result_marker_hash.each do |marker, gibson_result|
    	num = gibson_result.length
    	num_arr = *(1..num)
    	ids = []
    	if marker == :non_amp
    		transformed_aliquots = gibson_result.collect {|g| produce new_sample g.sample.name, of: "Plasmid", as: "Transformed E. coli Aliquot"}
    		ids = transformed_aliquots.collect {|t| t.id} 
    	elsif marker == :amp
    		ids = *(1..num)
    	end

	    show {
	    	title "Retrieve cuvettes and electrocompetent aliquots"
	    	check "Retrieve #{num} cuvettes put all inside the styrofoam touching ice block."
	    	check "Retrieve #{num} DH5alpha electrocompetent aliquots and place it on the aluminum tube rack."
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
	    	check "Label each electrocompetent aliquots with #{num_arr}."
	    	note "If still frozen, wait till the cells have thawed to a slushy consistency."
	    	warning "Transformation efficiency depends on keeping electrocompetent cells ice-cold until electroporation."
	    	warning "Do not wait too long"
	        image "thawed_electrocompotent_cells"
	    }


	    show {
	    	title "Pipette plasmid into electrocompetent aliquot"
	    	note "Pipette according to the following table"
	    	table [["Plasmid/Gibson Result, 2 µL", "Electrocompetent aliquot"]].concat(gibson_result.collect {|g| { content: g.id, check: true }}.zip num_arr)
	    }
	end

    release gibson_results, interactive: true, method: "boxes"
  end #main

end #Protocol