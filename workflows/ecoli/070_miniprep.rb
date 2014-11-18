#First version by Arjun, improved by Yaoyu.
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      elution_volume: 50,
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
    end
    io_hash[:primer_ids] = io_hash[:primer_ids].compact

    # delete correspnding initials
    if io_hash[:initials]
      io_hash[:initials].each_with_index do |inits,idx|
        io_hash[:initials][idx] = nil if verify_growth[:"verify#{overnights[idx].id}".to_sym] == "No"
      end
    end
    io_hash[:initials] = io_hash[:initials].compcat


    overnights = overnights.delete_if { |x| verify_growth[:"verify#{x.id}".to_sym] == "No"}

    num = overnights.length
    num_arr = *(1..num)
    
    show{
      title "Transfer overnights into 1.5 mL tubes"
      check "Label #{num} 1.5 mL tubes with 1 to #{num}"
      check "Pipette 1.5 mL of overnight cultures into the 1.5 mL tubes using the following table"
      table [["Overnight", "1.5 mL tube"]].concat(overnights.collect {|s| { content: s.id, check: true }}.zip num_arr)
    }
    
    show{
      title "Spin down the cells"
      check "Spin at 5,800 xg for 2 minutes, make sure to balance."
      check "Remove the supernatant. Pour off the supernatant into liquid waste, being sure not to upset the pellet. Pipette out the residual supernatant."
    }
    
    show{
      title "Resuspend in P1, P2, N3"
      check "Add 250 µL of P1 into each tube and vortex strongly to resuspend."
      check "Add 250 µL of P2 and gently invert 5-10 times to mix, tube contents should turn blue."
      check "Pipette 350 µL of N3 into each tube and gently invert 5-10 times to mix. Tube contents should turn colorless."
      warning "Time between adding P2 and N3 should be minimized. Cells should not be exposed to active P2 for more than 5 minutes"
    }
    
    
    show{
      title "Centrifuge and add to columns"
      check "Spin tubes at 17,000 xg for 10 minutes"
      warning "Make sure to balance the centrifuge."
      check "Grab #{num} blue miniprep spin columns and label with 1 to #{num}."
      check "Remove the tubes from centrifuge and carefully pipette the supernatant (up to 750 µL) into the same labeled columns."
      warning "Be careful not to disturb the pellet."
      check "Discard the used 1.5 mL tubes into waste bin."
    }

    show{
      title "Spin and wash"
      check "Spin all columns at 17,000 xg for 1 minute. Make sure to balance."
      check "Remove the columns from the centrifuge and discard the flow through into a liquid waste container"
      check "Add 750 µL of PE buffer to each column. Make sure the PE bottle that you are using has ethanol added!"
      check "Spin the columns at 17,000 xg for 1 minute"
      check "Remove the columns from the centrifuge and discard the flow through into a liquid waste container."
      check "Perform a final spin: spin all columns at 17,000 xg for 1 minute."
    }
    
    show{
      title "Elute with water"
      check "Grab #{num} new 1.5 mL tubes and label top of the tube with 1 to #{num}."
      check "Remove the columns from the centrifuge"
      check "Inidividually take each column out of the flowthrough collector and put it into the labeled 1.5 mL tube with the same number, discard the flowthrough collector."
      warning "For this step, use a new pipette tip for each sample to avoid cross contamination"
      check "Pipette #{elution_volume} µL of water into the CENTER of each column"
      check "Let the tubes sit on the bench for 2 minutes"
      check "Spin the columns at 17,000 xg for 1 minute"
      check "Remove the tubes and discard the columns"
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
  		ps.datum = { concentration: data["conc#{ps.id}".to_sym], volume: volume }
      ps.save
  	end

    # change overnights location to DFP.4
    move overnights, "DFP.4"
    
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
end # Protocol
