needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the item id that you are going to start overnight with
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
    io_hash = { inducers: [], yeast_strain_ids:[], inducers: [], volume: 1000, dilution_rate: 0.01, media_type: "800 mL SC liquid (sterile)" }.merge io_hash
    io_hash[:inducer_additions] = []
    yeast_strains = []
    io_hash[:yeast_strain_ids].each_with_index do |yid,idx|
      yeast_strain = find(:sample, id: yid)[0]
      yeast_strains.push yeast_strain
      io_hash[:inducer_additions].push "None"
      (io_hash[:inducers][idx] || []).each do |inducer|
        yeast_strains.push yeast_strain
        io_hash[:inducer_additions].push inducer
      end
    end

    yeast_plate_sections = []
    divided_yeast_plates = []

    yeast_strains.each do |y|
      yeast_collections = collection_type_contain_has_colony y.id, "Divided Yeast Plate"
      yeast_plate = yeast_collections[0]
      divided_yeast_plates.push yeast_plate
      yeast_plate_sections.push "#{yeast_plate.id}.#{yeast_plate.datum[:matrix][0].index(y.id)+1}"
    end

    take divided_yeast_plates.uniq, interactive: true
    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from Divided Yeast Plate into Eppendorf 96 Deepwell Plate."
    }
    deepwells = produce spread yeast_strains, "Eppendorf 96 Deepwell Plate", 8, 12
    show {
      title "Take deepwell plate"
      note "Grab #{deepwells.length} Eppendorf 96 Deepwell Plate. Label with #{deepwells.collect {|d| d.id}}."
    }
    media_str = (1..yeast_plate_sections.length).collect { |y| "#{io_hash[:volume]} µL"}
    load_samples_variable_vol( ["#{io_hash[:media_type]}","Divided Yeast Plate", "Inducers"], [
        media_str, yeast_plate_sections,io_hash[:inducer_additions]
      ], deepwells )
    show {
      title "Seal the deepwell plate(s) with a breathable sealing film"
      note "Put a breathable sealing film on following deepwell plate(s) #{deepwells.collect {|d| d.id}}."
      note "Place the deepwell plate(s) into the 30 C shaker incubator, make sure it is secure."
    }
    deepwells.each do |d|
      d.location = "30 C shaker incubator"
      d.save
    end

    release deepwells
    release divided_yeast_plates.uniq, interactive: true

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
