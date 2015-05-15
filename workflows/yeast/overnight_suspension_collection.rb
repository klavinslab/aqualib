needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL YPAD liquid (sterile)",
      yeast_strain_ids: [1668,1669,6518,6515],
      #The volume of the overnight suspension to make
      volume: 2,
      debug_mode: "Yes"
    }
  end

  def main

    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", yeast_strain_ids: [], overnight_ids: [], volume: 2, media_type: "800 mL YPAD liquid (sterile)" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    yeast_items = []
    yeast_plate_sections = [] # record where exactly the plate id and section the yeast_strain_id appears in yeast items.

    yeast_strain_available_ids = []
    yeast_strain_unavailable_ids = []

    io_hash[:yeast_strain_ids].each do |yid|
      yeast_collections = collection_type_contain yid, "Divided Yeast Plate", 60
      if yeast_collections.length > 0
        yeast_plate = yeast_collections[0]
        yeast_items.push yeast_plate
        yeast_plate.datum[:matrix][0]
        yeast_plate_sections.push "#{yeast_plate.id}.#{yeast_plate.datum[:matrix][0].index(yid)+1}"
        yeast_strain_available_ids.push yid
      else
        yeast_strain_unavailable_ids.push yid
      end
    end

    if io_hash[:volume] <= 2
      io_hash[:tube_size] = 14
    elsif io_hash[:volume] > 2
      io_hash[:tube_size] = 20
    end

    show {
      title "Testing page"
      note "#{yeast_plate_sections}"
      note "#{io_hash}"
    } if io_hash[:debug_mode] == "Yes"

    overnights = []

    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from divided yeast plates."
      note "The following yeast strains will be prepared overnights: " + yeast_strain_available_ids.join(', ') if yeast_strain_available_ids.length > 0
      note "The following yeast strains will not be prepared since no divided yeast plates contain them: " + yeast_strain_unavailable_ids.join(', ') if yeast_strain_unavailable_ids.length > 0
    }
    if yeast_strain_available_ids.length > 0
      overnights = yeast_strain_available_ids.collect { |id| find(:sample, id: id)[0].make_item "Yeast Overnight Suspension" }
      overnights.each do |y|
        y.location = "30 C shaker incubator"
        y.save
      end
      show {
        title "Media preparation in media bay"
        check "Grab #{overnights.length} of #{io_hash[:tube_size]} mL Test Tube"
        check "Add #{io_hash[:volume]} mL of #{io_hash[:media_type]} to each empty #{io_hash[:tube_size]} mL test tube using serological pipette"
        check "Write down the following ids on the cap of each test tube using dot labels #{overnights.collect {|x| x.id}}"
      }
      take yeast_items.uniq, interactive: true
      inoculation_tab = [["Item id.section", "#{io_hash[:tube_size]} mL tube id"]]
      yeast_plate_sections.each_with_index do |y, idx|
        inoculation_tab.push [ { content: "#{y}", check: true }, overnights[idx].id ]
      end
      show {
        title "Inoculation"
        note "Inoculate yeast into test tube according to the following table. Return items after innocuation."
        check "Take a sterile 10 µL tip, pick up a medium sized colony by gently scraping the tip to the colony."
        table inoculation_tab
      }
      release yeast_items.uniq, interactive: true
      release overnights, interactive: true, method: "boxes"
    else
      show {
        title "No overnights need to be prepared"
        note "Thanks for your effort!"
      }
    end

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"overnight")
      end
    end

    io_hash[:old_overnight_ids]  = io_hash[:overnight_ids]

    io_hash[:overnight_ids] = overnights.collect {|x| x.id}

    return { io_hash: io_hash }
  end

end
