needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning
  
  def cloning_verification_status
    # find all cloning verification tasks and arrange them into lists by status
    tasks = find(:task,{task_prototype: { name: "Cloning Verification" }})
    waiting = tasks.select { |t| t.status == "waiting" }
    overnight = tasks.select { |t| t.status == "overnight" }
    plasmid_extracted = tasks.select { |t| t.status == "plasmid extracted" }
    send_to_sequencing = tasks.select { |t| t.status == "send to sequencing" }
    done = tasks.select { |t| t.status == "results back" }

    return {
      waiting_ids: (tasks.select { |t| t.status == "waiting for fragments" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id},
      running_ids: running.collect { |t| t.id },
      done_ids: done.collect { |t| t.id }
    }
  end ### cloning_verification_status

  def arguments
    {
      io_hash: {},
      #Enter the plate ids as a list
      plate_ids: [3798,3797,3799],
      initials: ["YY","YY","YY"],
      num_colonies: [1,2,3],
      primer_ids: [[2575,2569,2038],[2054,2038],[2575,2569]],
      debug_mode: "Yes"
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
    io_hash.merge { plate_ids: [], num_colonies: [], primer_ids: [], initials: [] } if input[:io_hash]
    tasks = find(:task,{task_prototype: { name: "Cloning Verification" }})
    waiting_ids = (tasks.select { |t| t.status == "waiting" }).collect {|t| t.id}
    waiting_ids.each do |tid|
      task = find(:task, id: tid)[0]
      io_hash[:plate_ids].concat task.simple_spec[:plate_ids]
      io_hash[:num_colonies].concat task.simple_spec[:num_colonies]
      io_hash[:primer_ids].concat task.simple_spec[:primer_ids]
      io_hash[:initials].concat [task.simple_spec[:initials]]*(task.simple_spec[:plate_ids].length)
      task.status = "overnight"
      task.save
    end
    # Parse out plate_ids, num_colonies, initials for plasmid that has marker info entered.
    info_needed_plate_ids = []
    plate_ids = []
    num_colonies = []
    primer_ids = []
    initials = []
    io_hash[:plate_ids].each_with_index do |pid,idx|
      if find(:item, id: pid)[0].sample.properties["Bacterial Marker"] == ""
        info_needed_plate_ids.push pid
      else
        plate_ids.push pid
        num_colonies.push io_hash[:num_colonies][idx]
        primer_ids.push io_hash[:primer_ids][idx]
        initials.push io_hash[:initials][idx]
      end
    end

    initials.collect!.with_index {|x,i| [x]*num_colonies[i]}
    initials = initials.flatten

    show {
      note "#{initials}"
    }

    show {
      title "Bacterial Marker info required"
      note "Plasmids corresponding to the following plate_ids need to enter Bacterial Marker info."
      note "#{info_needed_plate_ids}"
    }

    plates = plate_ids.collect { |x| find(:item, id: x)[0] }
    overnights = []
    colony_plates = []
    sequencing_primer_ids = []
    # produce overnights based on plates and num_colonies
    # produce colony_plates which duplicate num_colonies for each plate and turn into array
    # produce sequencing_primer_ids which duplicate num_colonies for each primer_ids and turn into array
    plates.each_with_index do |p,idx|
      overnights.concat((1..num_colonies[idx]).collect { |n| produce new_sample p.sample.name, of: "Plasmid", as: "TB Overnight of Plasmid" })
      colony_plates.concat((1..num_colonies[idx]).collect { |n| p })
      sequencing_primer_ids.concat((1..num_colonies[idx]).collect { |n| primer_ids[idx] })
    end
    overnight_marker_hash = Hash.new {|h,k| h[k] = [] }
    overnights.each do |x|
      overnight_marker_hash[x.sample.properties["Bacterial Marker"].downcase[0,3]].push x
    end

    overnight_marker_hash.each do |marker, overnight|
      show {
        title "Media preparation in media bay"
        check "Grab #{overnight.length} of 14 mL Test Tube"
        check "Add 3 mL of TB+#{marker[0].upcase}#{marker[1..marker.length]} to each empty 14 mL test tube using serological pipette"
        check "Write down the following ids on cap of each test tube using dot labels #{overnight.collect {|x| x.id}}"
      }
    end

    take plates, interactive: true

    show {
      title "Inoculation"
      note "Use 10 µL sterile tips to inoculate colonies from plate into 14 mL tubes according to the following table."
      check "Mark each colony on the plate with corresponding overnight id. If the same plate id appears more than once in the table, inoculate different isolated coloines on that plate."
      table [["Plate id", "Overnight id"]].concat(colony_plates.collect { |p| p.id }.zip overnights.collect { |o| { content: o.id, check: true } })
    }

    # change location to 37 C shaker incubator

    overnights.each do |o|
      o.location = "37 C shaker incubator"
      o.save
    end
    release overnights, interactive: true
    release plates, interactive: true
    # Return all io_hash related info
    io_hash[:task_ids] = waiting_ids
    io_hash[:plate_ids] = plate_ids
    io_hash[:num_colonies] = num_colonies
    io_hash[:overnight_ids] = overnights.collect { |o| o.id }
    io_hash[:primer_ids] = sequencing_primer_ids
    io_hash[:initials] = initials
    return { io_hash: io_hash }

  end # main
end # Protocol