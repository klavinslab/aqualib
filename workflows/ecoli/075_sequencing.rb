needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
  
  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      initials: ["YY","YY"],
      plasmid_stock_ids: [15417,15418],
      primer_ids: [[2575,2569],[2054,2569]],
      debug_mode: "No",
      group: "yang"
    }
  end
 
  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash[:task_ids] = [] unless io_hash[:task_ids] # set default of io_hash[:task_ids]
    batch_initials = "MP"
    # turn input plasmid_stock_ids and primer_ids into two corresponding arrays
    plasmid_stock_ids = []
    primer_ids = []
    initials = []
    # show {
    #   note "#{io_hash}"
    # }
    idx = 0
    io_hash[:primer_ids].each_with_index do |pids|
      unless pids == []
        unless find(:item, id: io_hash[:plasmid_stock_ids][idx])[0].datum[:concentration] == 0
          primer_ids.concat pids
          (1..pids.length).each do
            plasmid_stock_ids.push io_hash[:plasmid_stock_ids][idx]
            initials.push io_hash[:initials][idx]
          end
        end
        idx += 1
      end
    end

    sequencing_info = task_status name: "Sequencing", group: io_hash[:group]
    io_hash[:sequencing_task_ids] = sequencing_info[:ready_ids]
    io_hash[:task_ids].concat io_hash[:sequencing_task_ids]
    io_hash[:sequencing_task_ids].each do |tid|
      ready_task = find(:task, id: tid)[0]
      ready_task.simple_spec[:primer_ids].each_with_index do |pids,idx|
        unless find(:item, id: ready_task.simple_spec[:plasmid_stock_id][idx])[0].datum[:concentration] == 0
          primer_ids.concat pids
          (1..pids.length).each do
            plasmid_stock_ids.push ready_task.simple_spec[:plasmid_stock_id][idx]
            initials.push ready_task.simple_spec[:initials]
          end
        end
      end
      # show {
      #   note "#{ready_task.spec}"
      # }
      io_hash[:task_ids].push tid
    end
    if plasmid_stock_ids.length == 0
      show {
        title "No sequencing needs to run."
        note "Thank you!"
      }
      return { io_hash: io_hash }
    end

    plasmid_stocks = plasmid_stock_ids.collect{|pid| find(:item, id: pid )[0]} 
    primer_aliquots = primer_ids.collect{|pid| find(:sample, id: pid )[0].in("Primer Aliquot")[0]}

    # create order table for sequencing
    sequencing_tab = [["DNA Name", "DNA Type", "DNA Length", "My Primer Name"]]
    plasmid_stocks.each_with_index do |p,idx|
      sequencing_tab.push ["#{p.id}-" + initials[idx], "Plasmid", p.sample.properties["Length"], primer_ids[idx]]
    end

    num = primer_ids.length
    genewiz = show {
      title "Create a Genewiz order"
      check "Go the Genewiz website, log in with lab account (Username: mnparks@uw.edu, password is the lab general password)."
      check "Click Create Sequencing Order, choose Same Day, Online Form, Pre-Mixed, #{num} samples, then Create New Form"
      check "Enter DNA Name and My Primer Name according to the following table, choose DNA Type to be Plasmid"
      table sequencing_tab
      check "Click Save & Next, Review the form and click Next Step"
      check "Enter Quotation Number MS0721101, click Next Step"  
      check "Print out the form and enter the Genewiz tracking number below."
      get "text", var: "tracking_num", label: "Enter the Genewiz tracking number", default: "10-277155539"
    }
    if io_hash[:group] != ("technicians" || "cloning" || "admin")
      primer_aliquots = primer_ids.collect{ |pid| choose_sample find(:sample, id: pid)[0].name, object_type: "Primer Aliquot" }
    end
    take plasmid_stocks + primer_aliquots, interactive: true, method: "boxes"
    plasmid_lengths = plasmid_stocks.collect{|pls| pls.sample.properties["Length"]}
    plasmid_concs = plasmid_stocks.collect{|pls| pls.datum[:concentration]}
    plasmid_volume_list = []
    plasmid_lengths.each_with_index do |length, idx|
    	if length < 6000
    		plasmid_volume_list.push (500.0/plasmid_concs[idx]).round(1)
    	elsif length < 10000
    		plasmid_volume_list.push (800.0/plasmid_concs[idx]).round(1)
    	else
    		plasmid_volume_list.push (10000.0/plasmid_concs[idx]).round(1)
    	end
    end
    water_volume_list = plasmid_volume_list.collect{|v| (12.5-v).to_s + " µL"}
    plasmids_with_volume = plasmid_stock_ids.map.with_index{|pid,i| plasmid_volume_list[i].to_s + " µL of " + pid.to_s}
    primers_with_volume = primer_aliquots.collect{|p| "2.5 µL of " + p.id.to_s }
    			
    # show {
    # 	note (water_volume_list.collect {|p| "#{p}"})
    # 	note (plasmid_volume_list.collect {|p| "#{p}"})
    # }

    stripwells = produce spread plasmid_stocks, "Stripwell", 1, 12
    show {
      title "Prepare Stripwells for sequencing reaction"
      stripwells.each_with_index do |sw,idx|
      	if idx < stripwells.length-1 and idx != stripwells.length-1
	        check "Grab a stripwell with 12 wells, label the first well with #{batch_initials}#{idx*12+1} and last well with #{batch_initials}#{idx*12+12}"
	        separator
	    else
	    	check" Grab a stripwell with #{plasmid_stocks.length.modulo(12)} wells, label the first well with #{batch_initials}#{idx*12+1} and last well with #{batch_initials}#{plasmid_stocks.length}"
        end
    end
    }

    load_samples_variable_vol( ["Molecular Grade Water", "Plasmid", "Primer"], [
        water_volume_list,
        plasmids_with_volume,
        primers_with_volume
      ], stripwells ) 
    show {
      title "Put all stripwells in the Genewiz mailbox"
      note "Cap all of the stripwells."
      note "Put the stripwells into a zip-lock bag along with the printed Genewiz order form."
      note "Ensure that the bag is sealed, and put it into the Genewiz mailbox"
    }
    release plasmid_stocks + primer_aliquots, interactive: true, method: "boxes"
    stripwells.each do |sw|
      sw.mark_as_deleted
      sw.save
    end
    # Set tasks in the io_hash to be send to sequencing
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"send to sequencing")
      end
    end
    # Return all info
    io_hash[:genewiz_tracking_no] = genewiz[:tracking_num]
    return { io_hash: io_hash }
  end
end
