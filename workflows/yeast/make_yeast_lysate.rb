needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_plate_ids: [32170,32171],
      num_colonies: [3,3],
      debug_mode: "No",
      group: "cloning"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # set default values
    io_hash = { yeast_plate_ids: [], num_colonies: [], debug_mode: "No", comb_1: "10 thin", comb_2: "10 thin", volume: 10 }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    raise "Incorrect inputs, yeast_plate_ids size does not match num_colonies size. They need to be one to one correspondence." if io_hash[:yeast_plate_ids].length != io_hash[:num_colonies].length

    yeast_items = io_hash[:yeast_plate_ids].collect {|yid| find(:item, id: yid )[0]}

    show {
      title "Protocol information"
      note "This protocol makes yeast lysates in stripwell tubes for the following plates:"
      note yeast_items.join(", ")
    }

    take yeast_items, interactive: true

    yeast_samples = []
    yeast_colonies = []
    yeast_items.each_with_index do |y,idx|
      start_colony = (y.datum[:QC_result] || []).length
      (1..io_hash[:num_colonies][idx]).each do |x|
        yeast_samples.push y.sample
        yeast_colonies.push "#{y.id}.c#{start_colony+x}"
      end
    end
    

    # build a pcrs hash that group fragment pcr by T Anneal
    pcrs = Hash.new { |h, k| h[k] = { yeast_samples: [], yeast_colonies: [], forward_primers: [], reverse_primers: [], stripwells: [] } }

    forward_primers = yeast_samples.collect { |y| y.properties["QC Primer1"] }
    reverse_primers = yeast_samples.collect { |y| y.properties["QC Primer2"] }

    yeast_samples.each_with_index do |y, idx|
      tanneal = (forward_primers[idx].properties["T Anneal"] + reverse_primers[idx].properties["T Anneal"])/2
      if tanneal >= 70
        pcrs[70][:yeast_samples].push y
        pcrs[70][:yeast_colonies].push yeast_colonies[idx]
      elsif tanneal >= 67
        pcrs[67][:yeast_samples].push y
        pcrs[67][:yeast_colonies].push yeast_colonies[idx]
      else
        pcrs[64][:yeast_samples].push y
        pcrs[64][:yeast_colonies].push yeast_colonies[idx]
      end
    end

    pcrs.each do |t, pcr|
      pcr[:stripwells] = produce spread pcr[:yeast_samples], "Stripwell", 1, 12
      pcr[:forward_primers] = pcr[:yeast_samples].collect { |y| y.properties["QC Primer1"] }
      pcr[:reverse_primers] = pcr[:yeast_samples].collect { |y| y.properties["QC Primer1"] }
    end

    stripwells = pcrs.collect { |t, pcr| pcr[:stripwells] }
    stripwells.flatten!

    show {
      title "Prepare Stripwell Tubes"
      stripwells.each do |sw|
        if sw.num_samples <= 6
          check "Grab a new stripwell with 6 wells and label with the id #{sw}."
        else
          check "Grab a new stripwell with 12 wells and label with the id #{sw}."
        end
        note "Pipette 25 µL of 20 mM NaOH into wells " + sw.non_empty_string + "."
        warning "Using 25 µL NaOH, not 30 µL SDS.  "
      end
      # TODO: Put an image of a labeled stripwell here
    }

    # add colonies to stripwells
    pcrs.each do |t, pcr|
      load_samples_variable_vol( [ "Colony cx from plate, 1/3 size" ], [
          pcr[:yeast_colonies],
        ], pcr[:stripwells] ) {
        note "For each plate id.cx (x = 1,2,3,...), if a colony cx is not marked on the plate, mark it with a circle and write done cx (x = 1,2,3,...) nearby. If a colony cx is alread marked on the plate, scrape that colony."
        note "Use a sterile 10 µL tip to scrape about 1/3 of the marked colony, swirl tip inside the well until mixed."
      }
    end

    # Run the thermocycler
    thermocycler = show {
      title "Start the lysate reactions"
      check "Put the cap on each stripwell #{stripwells.collect { |sw| sw.id } }. Press each one very hard to make sure it is sealed."
      check "Vortex all the stripwells on a green tube holder on a vortexer."
      check "Place the stripwells into an available thermal cycler and close the lid."
      get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
      separator
      check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'LYSATE'."
      check "Press 'run' and select 25 µL."
      # TODO: image: "thermal_cycler_home"
    }

    # Set the location of the stripwells to be the name of the thermocycler
    stripwells.each do |sw|
      sw.move thermocycler[:name]
    end

    release stripwells
    release yeast_items, interactive: true

    show {
      title "Wait for 10 minutes"
      timer initial: { hours: 0, minutes: 5, seconds: 0}
    }

    take stripwells, interactive: true

    show {
      title "Keep stripwells"
          check "Keep the new stripwell on the bench for the next protocol to use."
          warning "DO NOT SPIN DOWN STIPWELLS."
    }

    stripwells.each do |sw|
      sw.move "Bench"
    end

    release stripwells

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"lysate")
      end
    end

    io_hash[:lysate_stripwell_ids] = stripwells.collect { |sw| sw.id }

    # To let metacol know whether to fire "move cartridge" protocol
    cartridge_in_analyzer = find(:item, object_type: { name: "QX DNA Screening Cartridge" }).select { |c| c.location.downcase == "fragment analyzer" }.any?
    
    return { io_hash: io_hash, cartridge_in_analyzer: cartridge_in_analyzer }
  end

end
