needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the item id that you are going to start overnight with
      yeast_item_ids: [13011, 15872],
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL SC liquid (sterile)",
      inducers: [["10 µM auxin", "20 µM auxin"],["10 µM auxin", "10 nM b-e"]],
      when_to_add_inducer: ["start", "dilute"],
      dilution_rate: 0.01,
      #The volume of the overnight suspension to make
      volume: 1000,
      task_mode: "Yes",
      group: "cloning",
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode] || "No"
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash = { inducers: [], yeast_item_ids:[], inducers: [], task_mode: "Yes", volume: 1000, dilution_rate: 0.01, media_type: "800 mL SC liquid (sterile)" }.merge io_hash
    if io_hash[:task_mode] == "Yes"
      tasks = find(:task,{ task_prototype: { name: "Cytometer Reading" } })
      waiting_ids = (tasks.select { |t| t.status == "waiting" }).collect {|t| t.id}
      io_hash[:task_ids] = task_group_filter(waiting_ids, io_hash[:group])
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:yeast_item_ids].concat task.simple_spec[:item_ids]
        io_hash[:inducers].concat task.simple_spec[:inducers]
      end
    end
    yeast_items = []
    io_hash[:inducer_additions] = []
    io_hash[:yeast_item_ids].each_with_index do |yid,idx|
      yeast_items.push find(:item, id: yid )[0]
      io_hash[:inducer_additions].push "None"
      (io_hash[:inducers][idx] || []).each do |inducer|
        yeast_items.push find(:item, id: yid )[0]
        io_hash[:inducer_additions].push inducer
      end
    end
    yeast_strains = yeast_items.collect { |y| y.sample }
    take yeast_items.uniq, interactive: true
    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from glycerol stocks, plates or overnight suspensions into Eppendorf 96 Deepwell Plate."
    }
    deepwells = produce spread yeast_strains, "Eppendorf 96 Deepwell Plate", 8, 12
    show {
      title "Take deepwell plate"
      note "Grab #{deepwells.length} Eppendorf 96 Deepwell Plate. Label with #{deepwells.collect {|d| d.id}}."
    }
    yeast_items_str = yeast_items.collect { |y| y.id.to_s }
    media_str = (1..yeast_items.length).collect { |y| "#{io_hash[:volume]} µL"}
    load_samples_variable_vol( ["#{io_hash[:media_type]}","Yeast items", "Inducers"], [
        media_str, yeast_items_str,io_hash[:inducer_additions]
      ], deepwells ) 
    show {
      title "Seal the plate with a breathable sealing film"
      note "Put a breathable sealing film on the plate after inoculation."
    }
    deepwells.each do |d|
      d.location = "30 C shaker incubator"
      d.save
    end
    
    yeast_items.each do |y|
      y.store
      y.reload
    end

    release deepwells + yeast_items.uniq, interactive: true
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"overnight")
      end
    end
    io_hash[:yeast_deepwell_plate_ids] = deepwells.collect {|d| d.id}
    return { io_hash: io_hash }
  end # main

end # Protocol
