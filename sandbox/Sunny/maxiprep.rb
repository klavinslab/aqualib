#First version by Arjun, refactored and task enabled by Yaoyu.
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      elution_volume: 1000,
      overnight_ids: [12389,12388,12387],
      debug_mode: "no"
    }
  end

  def main
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
      note "Choose No for the overnight that does not have growth and throw them away or put in the clean station."
      overnights.each do |x|
        select ["Yes", "No"], var: "verify#{x.id}", label: "Does tube #{x.id} have growth?"
      end
    }

    overnights_to_delete = overnights.select { |x| verify_growth[:"verify#{x.id}".to_sym] == "No"}
    delete overnights_to_delete

    # delete correspnding primer_ids
    if io_hash[:primer_ids]
      io_hash[:primer_ids].each_with_index do |pids,idx|
        io_hash[:primer_ids][idx] = nil if verify_growth[:"verify#{overnights[idx].id}".to_sym] == "No"
      end
      io_hash[:primer_ids] = io_hash[:primer_ids].compact
    end
    
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
    
    show{
      title "Transfer the culture into centrifuge tubes"
      check "Label 4 250 mL centrifuge tubes with #{overnight_ids}"
      check "Divide overnight culture equally between four tubes. Each should have approximately 200 ml culture."
      }
    
    
    show{
      title "Spin down the cells"
      check "Spin at 14,000 rcf (6,000Xg) for 15 min at 4 C"
      check "Remove the supernatant. Pour off the supernatant into liquid waste, being sure not to upset the pellet. Pipette out the residual supernatant."
    }
    
    show{
      title "Resuspend in P1"
      check "Add 20 mL of P1 into each tube using the serological pipet and vortex strongly to resuspend."
    }
    
    show{
      title "Consolidate samples"
      check "Pour all samples with same overnight id into one 250 mL centrifuge tube."
    }
    
    show{
      title "Add P2, P3"
      check "Add 80 mL of P2 into each tube using the serological pipet and gently invert to mix."
      check "Incubate at room temperature (15-25 C) for 5 min."
		warning "This step should be done rapidly. Cells should not be exposed to active P2 for more than 5 minutes. During incubation, go to the next step and prepare the QIAfilter Cartridge and HiSpeed Tip."
    }
    
    show{
		title "Prepare equipment during incubation (5 min)"
		check "During the incubation, take out a QIAfilter Cartridge. Screw the cap onto the outlet nozzle of the QIAfilter Cartridge. Place the QIAfilter Cartridge into a convenient tube or test tube rack."
		check "Place a HiSpeed Tip onto a tip holder which is resting on a 250 ml beaker. Add 10ml of QBT buffer to the HiSpeed Tip, allowing it to enter the resin."
    }

    show{
        title "Add Prechilled P3 and gently invert to mix"
		check "Pipette 80 ml of prechilled P3 into each tube with serological pipette and gently invert 4 -6 times to mix."
    }
    
    
    show{
      title "Spin down the cells"
      check "Spin at 14,000 rcf (6,000Xg) for 15 min at 4 C"
    }
    
   show{
      title "Filter lysate through QIAfilter Cartridge into HiSpeed tip"
	check "Remove the cap from the QIAfilter Cartridge outlet nozzle. Gently insert the plunger into the QIAfilter Cartridge, and depress slowly so the cell lysate enters the HiSpeed Tip."
	check "Discard the QIAfilter Cartridge after all lysate has been removed."
	}
	
	show{
	title "Wash HiSpeed tip with QC buffer"
	check "After the lysate has entered, add 60ml Buffer QC to the HiSpeed tip. Allow the wash to fiter through the tip by gravity flow."
	warning "Do not proceed to the next step until all wash liquid has filtered through the tip."
	}

	show{
	title "Elute DNA into a new 50ml tube"
	check "Place a new 50 ml tube without the cap in a tube stand. Take the HiSpeed tip and tip stand and move them so they are over the 50ml tube."
	check "Add 15ml Buffer QF to the HiSpeed tip to elute DNA into the 50ml tube."
	warning "Do not elute DNA into the waste container from the previous step, or DNA will be lost!"
	}


	show{
		title "Precipitate DNA in 50ml tube"
		check "Precipitate DNA by adding 10.5 ml ispropanol. Put the lid on the 50 ml tube, mix gently by inverting, and incubate for 5 min."
		check "During the incubation, remove the plunger from a new 30 ml syringe and attach the QIAprecipitator Module onto the outlet nozzle."
	}

	show{
		title "Filter DNA through QIAprecipitator"
		check "Place the QIAprecipitator over a waste bottle, transfer the eluate-isopropanol mixture from the 50 ml tube into the syringe, and insert the plunger. Filter the mixture through the QIAprecipitator using constant pressure."
	}

	show{
		title "Wash DNA with 70 percent ethanol"
		check "Remove the QIAprecipitator from the syringe and pull out the plunger. Re-attach the QIAprecipitator and add 2ml 70 percent ethanol to the syringe. Wash the DNA by the inserting the plunger and pressing the ethanol through the QIAprecipitator."
	}

	show{
		title "Dry the QIAprecipitator membrane"
		check "Remove the QIAprecipitator from the syringe and pull out the plunger carefully. Re-attach the QIAprecipitator, insert the plunger, and dry the membrane by pressing air through the QIAprecipitatior quickly. Repeat the whole step several times."
		check "Dry the outlet nozzle of the QIAprecipitator with a paper towel."
	}

	show{
		title "Elute DNA into 1.5 ml collection tube"
		check "Remove the plunger from a new 5 ml syringe, attach the QIAprecipitator and hold the outlet over a 1.5 ml collection tube." 
		check "Add 1 ml Buffer TE to the 5 ml syringe."
		check "Insert the plunger and elute the DNA into the collection tube using constant pressure."
	}

	show{
		title "Final filtering"
		check "Remove the QIAprecipitator from the 5 ml syringe, pull out the plunger and re-attach the QIAprecipitator to the 5 ml syringe." 
		check "Transfer the eluate from the 1.5 ml tube into the 5 ml syringe and elute for a second time into the same 1.5 ml tube."
	}
    
    plasmid_stocks = overnights.collect { |x| produce new_sample x.sample.name, of: "Plasmid", as: "Plasmid Stock"}
    
    show{
      title "Re-label all 1.5 mL tubes"
      note "Add a white sticker to the top of each tube and relabel them according to the following table"
      table [["Tube number","New item id"]].concat(num_arr.zip plasmid_stocks.collect{ |p| { content: p.id, check: true } })
    }
    
    data = show {
      title "Nanodrop all labeled 1.5 mL tubes"
      plasmid_stocks.each do |plasmid|
        get "number", var: "conc#{plasmid.id}", label: "Enter concentration of #{plasmid.id}", default: 200 
      end
    }

    volume = elution_volume - 2

  	plasmid_stocks.each_with_index do |ps,idx|
  		ps.datum = { concentration: data["conc#{ps.id}".to_sym], volume: volume, from: overnights[idx].id }
      ps.save
  	end

    # restore overnights location to be managed by location wizard
    overnights.each do |o|
      o.store
      o.reload
    end
    
  	release overnights, interactive: true
  	release plasmid_stocks, interactive: true, method: "boxes"
    # Set tasks in the io_hash to be plasmid extracted
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"plasmid extracted")
      end
    end
    # Return io_hash
    io_hash[:overnight_ids] = overnights.collect { |o| o.id }
    io_hash[:plasmid_stock_ids] = plasmid_stocks.collect { |p| p.id}
    return { io_hash: io_hash }
  end # main
end