needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the plate ids as a list
      plate_ids: [48087,48086,48082],
      num_colonies: [1,2,3],
      primer_ids: [[2575,2569,2038],[2054,2038],[2575,2569]],
      glycerol_stock_ids: [8763,8759,8752],
      debug_mode: "Yes",
      group: "cloning"
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    # making sure have the following hash indexes.
    io_hash = { plate_ids: [], num_colonies: [], primer_ids: [], glycerol_stock_ids: [] }.merge io_hash

    # raise errors if inputs are not valid
    raise "Incorrect inputs, plate_ids and num_colonies must have the same length." if io_hash[:plate_ids].length != io_hash[:num_colonies].length
    raise "Incorrect inputs, plate_ids and primer_ids must have the same length." if io_hash[:plate_ids].length != io_hash[:primer_ids].length

    # Parse out plate_ids, num_colonies, initials for plasmid that has marker info entered.
    info_needed_plate_ids = []
    plate_ids = []
    num_colonies = []
    primer_ids = []
    io_hash[:plate_ids].each_with_index do |pid,idx|
      if find(:item, id: pid)[0].sample.properties["Bacterial Marker"] == ""
        info_needed_plate_ids.push pid
      else
        plate_ids.push pid
        num_colonies.push io_hash[:num_colonies][idx]
        primer_ids.push io_hash[:primer_ids][idx]

        # record how many times this plate has been started overnight from
        plate = find(:item, id: pid)[0]
        num_of_overnights_started = plate.datum[:num_of_overnights_started] || 0
        num_of_overnights_started += io_hash[:num_colonies][idx]
        plate.datum = (plate.datum).merge({ num_of_overnights_started: num_of_overnights_started } )
        plate.save

      end
    end

    show {
      title "Bacterial Marker info required"
      note "Plasmids corresponding to the following plate_ids need to enter Bacterial Marker info."
      note "#{info_needed_plate_ids}"
    } if info_needed_plate_ids.length > 0

    plates = plate_ids.collect { |x| find(:item, id: x)[0] }
    overnights = []
    colony_plates = []
    sequencing_primer_ids = []

    # produce overnights based on plates and num_colonies, add datum from to track from which plate
    # produce colony_plates which duplicate num_colonies for each plate and turn into array
    # produce sequencing_primer_ids which duplicate num_colonies for each primer_ids and turn into array
    plates.each_with_index do |p,idx|
      new_overnights = (1..num_colonies[idx]).collect { |n| produce new_sample p.sample.name, of: "Plasmid", as: "TB Overnight of Plasmid" }
      new_overnights.each do |x|
        x.datum = { from: p.id }
        x.save
      end
      overnights.concat new_overnights
      colony_plates.concat((1..num_colonies[idx]).collect { |n| p })
      sequencing_primer_ids.concat((1..num_colonies[idx]).collect { |n| primer_ids[idx] })
    end

    glycerol_overnights = []
    if io_hash[:glycerol_stock_ids].length > 0
      glycerol_overnights = io_hash[:glycerol_stock_ids].collect { |id| produce new_sample find(:item, id: id)[0].sample.name, of: "Plasmid", as: "TB Overnight of Plasmid" }
      glycerol_overnights.each_with_index do |x, idx|
        x.datum = { from: io_hash[:glycerol_stock_ids][idx] }
        x.save
      end
    end

    all_overnights = overnights + glycerol_overnights

    overnight_marker_hash = Hash.new {|h,k| h[k] = [] }
    all_overnights.each do |x|
      marker_key = "TB"
      x.sample.properties["Bacterial Marker"].split(',').each do |marker|
        marker_key = marker_key + "+" + formalize_marker_name(marker)
      end
      overnight_marker_hash[marker_key].push x
    end

    overnight_marker_hash.each do |marker, overnight|
      show {
        title "Media preparation in media bay"
        check "Grab #{overnight.length} of 14 mL Test Tube"
        check "Add 3 mL of #{marker} to each empty 14 mL test tube using serological pipette"
        check "Write down the following ids on cap of each test tube using dot labels #{overnight.collect {|x| x.id}}"
      }
    end

    take plates, interactive: true

    show {
      title "Inoculation from plate"
      note "Use 10 µL sterile tips to inoculate colonies from plate into 14 mL tubes according to the following table."
      check "Mark each colony on the plate with corresponding overnight id. If the same plate id appears more than once in the table, inoculate different isolated coloines on that plate."
      table [["Plate id", "Overnight id"]].concat(colony_plates.collect { |p| p.id }.zip overnights.collect { |o| { content: o.id, check: true } })
    }

    if io_hash[:glycerol_stock_ids].length > 0
      glycerol_stocks = io_hash[:glycerol_stock_ids].collect { |id| find(:item, id: id)[0] }
      take glycerol_stocks
      tab = [["Glycerol stock id", "Location", "Overnight id"]]
      glycerol_stocks.each_with_index do |g,idx|
        tab.push [g.id, { content: g.location, check: true }, { content: glycerol_overnights[idx].id, check: true } ]
      end

      show {
        title "Inoculation from glycerol stock"
        note "Extremely careful about sterile technique in this step!!!"
        check "Grab one glycerol stock at a time! Use a pipettor with a 100 µL sterile tip to vigerously scrape the glycerol stock to get a chunk of stock, add and mix into the 14 mL overnight tubes according to the following table. Return glycerol stock immediately after use."
        table tab
      }
    end

    # change location to 37 C shaker incubator

    all_overnights.each do |o|
      o.location = "37 C shaker incubator"
      o.save
    end
    release all_overnights, interactive: true
    release plates, interactive: true

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"overnight")
      end
    end

    # Return all io_hash related info
    io_hash[:plate_ids] = plate_ids
    io_hash[:num_colonies] = num_colonies
    io_hash[:overnight_ids] = overnights.collect { |o| o.id }
    io_hash[:glycerol_overnight_ids] = glycerol_overnights.collect { |o| o.id }
    io_hash[:primer_ids] = sequencing_primer_ids
    return { io_hash: io_hash }

  end # main
end # Protocol
