needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      elution_volume: 1000,
      overnight_ids: [33195,33196],
      debug_mode: "no"
    }
  end

  def main
      
      show{
      	title "Set centrifuge to 4 degrees C"
      }
    
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    overnight_ids = io_hash[:overnight_ids]
    elution_volume = io_hash[:elution_volume] || 50

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # Find all overnights and take them
    overnights = overnight_ids.collect{ |oid| find(:item,id:oid)[0] }
    take overnights, interactive: true

    verify_growth = show {
      title "Check if overnights have growth"
      note "Choose No for the overnight that does not have growth. Empty flask and put in the clean station."
      overnights.each do |x|
        select ["Yes", "No"], var: "verify#{x.id}", label: "Does flask #{x.id} have growth?"
      end
    }

    overnights_to_delete = overnights.select { |x| verify_growth[:"verify#{x.id}".to_sym] == "No"}
    delete overnights_to_delete
    
    # delete correspnding initials
    if io_hash[:initials]
      io_hash[:initials].each_with_index do |inits,idx|
        io_hash[:initials][idx] = nil if verify_growth[:"verify#{overnights[idx].id}".to_sym] == "No"
      end
      io_hash[:initials] = io_hash[:initials].compact
    end

    overnights = overnights.delete_if { |x| verify_growth[:"verify#{x.id}".to_sym] == "No"}

    num = overnights.length
    num_arr = *(1..num)
 
    overnights.each do |x|
        show{ title "Transfer culture into centrifuge tubes"
        	check "Label 1 50 mL falcon tube with overnight id #{x.id}" 
        	check "Transfer 50 ml of overnight culture #{x.id} into each labeled tube."
        	}
    end
      
    overnights.each do |x|  
    show{
      title "Spin down the cells labeled as #{x.id}"
      check "Spin at 4,696 xg for 15 min at 4 C"
      check "Once you've started the centrifuge, click ok" 
      }
    end
  
  	show{
		title "Place all empty flasks at the clean station"
		}
    
    show{
		title "Prepare equipment during spin"
		check "During the spin, take out #{num} QIAfilter Cartridge(s). Label them with #{overnight_ids}. Screw the cap onto the outlet nozzle of the QIAfilter Cartridge(s). Place the QIAfilter Cartridge(s) into a convenient tube or test tube rack."
		check "Label #{num} HiSpeed Tip(s). Place the HiSpeed Tip(s) onto a tip holder, resting on a 250 ml beaker. Add 4 mL of QBT buffer to the HiSpeed Tip(s), allowing it to enter the resin."
   		 }

	show{
		title "Retrieve centrifuge tubes"
	    check "Remove the supernatant from all the tubes. Pour off the supernatant into liquid waste, being sure not to upset the pellet. Pipette out the residual supernatant."
    	}
    
    show{
      title "Resuspend cells in P1"
      check "Add 6 mL of P1 into each centrifuge tube using the serological pipet and vortex strongly to resuspend."
    	}
    
    show{
      title "Add P2"
      check "Add 6 mL of P2 into each centrifuge tube using the serological pipette and gently invert 4-6 times to mix."
      check "Incubate tube at room temperature for 5 minutes."
		  
      warning "Cells should not be exposed to active P2 for more than 5 minutes."
      }
    

    show{
        title "Add prechilled P3 and gently invert to mix"
		    check "Pipette 6 mL of prechilled P3 into each tube with serological pipette and gently invert 4-6 times to mix."
    	}
    
    show{
      title "Centrifuge tubes at 20,000 X g for 15 mins at 4 C "
      check "Once you've started the centrifuge, click ok"
    	}
    
    overnights.each do |x|  
    show{
    	title "Filter lysate #{x.id} through QIAfilter Cartridge into HiSpeed tip"
		check "Pour #{x.id} lysate from the centrifuge tube into the capped QIAfilter Cartridge labeled #{x.id}."
		check "Remove the plunger from a 30 mL syringe."
		check " Take the cap off the QIAfilter Cartridge outlet nozzle. Gently insert the plunger 
			into the QIAfilter Cartridge, and depress slowly so the cell lysate enters the HiSpeed Tip labeled #{x.id} ."
		check "Continue doing this until all the lysate has been transfered to the HiSpeed Tip"
		check "Discard the QIAfilter Cartridge after all lysate has been removed."
		}
    end
    
	show{
		title "Wash HiSpeed tips with QC buffer"
		check "After all the lysate has entered, add 20 mL Buffer QC to each HiSpeed tip #{overnight_ids}. Allow the wash to fiter through the tip by gravity flow."
		check "While you are waiting for the buffer to filter through the tip, get #{num} 50 mL falcon tubes. Label them #{overnight_ids} respectively and put them in a tube stand."
		warning "Do not proceed to the next step until all wash liquid has filtered through the tip (it stops dripping)."
		}

    overnights.each do |x| 
	show{
		title "Elute DNA into 50 mL tube"
		check "Place the cap off the 50 mL tube labeled #{x.id}. Take the HiSpeed tip labeled #{x.id} and tip stand and move them so they are over the 50ml tube."
		check "Add 5 mL Buffer QF to the HiSpeed tip to elute DNA into the 50ml tube."
		warning "Do not elute DNA into the waste container, or DNA will be lost!"
		}
	end

	show{
		title "Discard HiSpeed tips"
		check "Discard the HiSpeed tips after the buffer has finished dripping through."
		}
	
	show{
		title "Precipitate DNA in 50ml tube"
		check "Precipitate DNA by adding 3.5 ml isopropanol to the #{num} 50 mL falcon tube(s). Put the lids back on the 50 ml tubes and mix gently by inverting. Let stand for 5 min."
		check "While waiting, click ok" 
		}
	
	show{
		title "Prepare equipment"
		check "Label #{num} QIAprecipitator modules(s) with #{overnight_ids} respectively"
		check "Remove the plunger from #{num} new 20 mL syringe and attach the labeled QIAprecipitator Module(s) to the outlet nozzle."
		}
	
    overnights.each do |x| 
	show{
		title "Filter DNA through QIAprecipitator"
		check "Place the QIAprecipitator labeled #{x.id} over a waste bottle, transfer the eluate-isopropanol mixture from the #{x.id} 50 ml tube into the syringe, and insert the plunger. Depress the plunger and filter the mixture through the QIAprecipitator."
		}
	end

	overnights.each do |x|
	show{
		title "Wash DNA with 70 percent ethanol"
		check "Remove the QIAprecipitator labeled #{x.id} from the syringe and pull out the plunger. Re-attach the QIAprecipitator and add 2ml 70 percent ethanol to the syringe. Wash the DNA by the inserting the plunger and pressing the ethanol through the QIAprecipitator."
		}
	end

	overnights.each do |x|	
	show{
		title "Dry the QIAprecipitator membrane"
		check "Remove the QIAprecipitator labeled #{x.id} from the syringe and pull out the plunger carefully. Re-attach the QIAprecipitator, insert the plunger, and dry the membrane by pressing air through the QIAprecipitatior quickly. Repeat the whole step 3 times."
		check "Dry the outlet nozzle of the QIAprecipitator with a paper towel. Discard the syringe and plunger"
		}
	end
	
	midipreps = overnights.collect { |x| produce new_sample x.sample.name, of: "Plasmid", as: "Midiprep Stock"}
    
    show{
      title "Prepare 1.5 mL tubes"
      note " Retrive #{num} 1.5 mL tubes and add a white sticker to the top of each tube. Label them with the item ids in the following table"
      table [["Tube number","Item id"]].concat(num_arr.zip midipreps.collect{ |p| { content: p.id, check: true } })
    	}

	overnights_midipreps_pairs = overnights.zip(midipreps)
	
	overnights_midipreps_pairs.each do |pair|
	show{
		title "Elute DNA into the 1.5 ml collection tubes"
		check "Remove the plunger from a new 5 ml syringe, attach the QIAprecipitator labeled #{pair[0]} and hold the outlet over the 1.5 ml collection tube labeled #{pair[1]}." 
		check "Add 1 ml Buffer TE to the 5 ml syringe."
		check "Insert the plunger and elute the DNA by depressing the plunger."
		}
	end

	overnights_midipreps_pairs.each do |pair|
	show{
		title "Final filtering"
		check "Remove the QIAprecipitator labeled #{pair[0]} from the 5 ml syringe, pull out the plunger and re-attach the QIAprecipitator to the 5 ml syringe." 
		check "Transfer the eluate from the 1.5 ml tube labeled #{pair[1]} into the 5 ml syringe and elute QIAprecipitator #{pair[0]} for a second time into the same 1.5 ml tube (labeled #{pair[1]})."
		}
	end
    
    data = show {
      title "Nanodrop all labeled 1.5 mL tubes"
      midipreps.each do |plasmid|
        get "number", var: "conc#{plasmid.id}", label: "Enter concentration of #{plasmid.id}", default: 1500 
      end
    }

    volume = elution_volume - 2

  	midipreps.each_with_index do |ps,idx|
  		ps.datum = { concentration: data["conc#{ps.id}".to_sym], volume: volume, from: overnights[idx].id }
      ps.save
  	end

    # restore overnights location to be managed by location wizard
    overnights.each do |o|
      o.store
      o.reload
    end
    
     overnights.each do |x|  
    	x.mark_as_deleted
    end
    
  	release overnights, interactive: false
  	release midipreps, interactive: true, method: "boxes"
    # Set tasks in the io_hash to be plasmid extracted
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"plasmid extracted")
      end
    end
    # Return io_hash
    io_hash[:overnight_ids] = overnights.collect { |o| o.id }
    io_hash[:plasmid_stock_ids] = midipreps.collect { |p| p.id}
    return { io_hash: io_hash }
  end # main
end