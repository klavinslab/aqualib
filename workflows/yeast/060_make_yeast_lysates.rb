needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
  	{
      io_hash: {},
  		yeast_plate_ids: [13578,13579],
  		num_colonies: [3,3],
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

    io_hash[:comb_1] = "6 thin"
    io_hash[:comb_2] = "6 thin"
    io_hash[:volume] = 10 # volume for PCR reaction

    # making sure have the following hash indexes.
    io_hash = io_hash.merge({ yeast_plate_ids: [], num_colonies: [] }) if !input[:io_hash]

    tasks = find(:task,{ task_prototype: { name: "Yeast Strain QC" } })
    waiting_ids = (tasks.select { |t| t.status == "waiting" }).collect {|t| t.id}
    io_hash[:task_ids] = waiting_ids
    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      io_hash[:yeast_plate_ids].concat task.simple_spec[:yeast_plate_ids]
      io_hash[:num_colonies].concat task.simple_spec[:num_colonies]
    end

    raise "Incorrect inputs, yeast_plate_ids size does not match num_colonies size. They need to be one to one correspondence." if io_hash[:yeast_plate_ids].length != io_hash[:num_colonies].length

  	show {
  		title "Protocol information"
  		note "This protocol makes yeast lysates in stripwell tubes"
  	}

  	yeast_items = io_hash[:yeast_plate_ids].collect {|yid| find(:item, id: yid )[0]}
  	take yeast_items, interactive: true

  	yeast_samples = []
  	yeast_colonies = []
  	yeast_items.each_with_index do |y,idx|
  		(1..io_hash[:num_colonies][idx]).each do |x|
  			yeast_samples.push y.sample
  			yeast_colonies.push y
  		end
  	end

  	sds = yeast_samples.length * 3 * 1.1
  	water = yeast_samples.length * 27 * 1.1

  	show {
  		title "Prepare 0.2 percent SDS"
  		check "Grab a 2 percent SDS stock."
  		check "Grab an empty 1.5 mL tube, label as 0.2 percent SDS."
  		check "Pipette #{sds.round(1)} µL of 2 percent SDS stock into the 1.5 mL tube."
  		check "Pipette #{water.round(1)} µL of molecular grade water into the 1.5 mL tube."
  		check "Mix with vortexer."
  	}

  	stripwells = produce spread yeast_samples, "Stripwell", 1, 12

    show {
      title "Prepare Stripwell Tubes"
      stripwells.each do |sw|
        check "Label a new stripwell with the id #{sw}."
        check "Pipette 30 µL of 0.2 percent SDS into wells " + sw.non_empty_string + "."
        separator
      end
    }

    load_samples( [ "Colony from plate, 1/3 size"], [
        yeast_colonies,
      ], stripwells ) {
      note "If colonies on the plate are already marked with circles as c1, c2, c3 ..., scrape colonies following the order on the plates for those marked colonies. Otherwise mark required number of colonies with c1, c2, c3, ..."
    	note "Use a sterile 10 µL tip to scrape about 1/3 of the marked colony, swirl tip inside the well until mixed."
    }

    # Run the thermocycler
    thermocycler = show {
      title "Start the lysate reactions"
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      separator
      check "Place the stripwells into an available thermal cycler and close the lid."
      get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
      separator
      check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'LYSATE'."
      check "Press 'run' and select 30 µL."
      # TODO: image: "thermal_cycler_home"
    }

    # Set the location of the stripwells to be the name of the thermocycler
    stripwells.each do |sw|
      sw.move thermocycler[:name]
    end

    release stripwells
    release yeast_items, interactive: true

    show {
    	title "Wait for 5 minutes"
    	timer initial: { hours: 0, minutes: 5, seconds: 0}
    }

    take stripwells, interactive: true
    show {
    	title "Spin down and dilute"
    	check "Spin down all stripwells until a small pellet is visible at the bottom of the tubes."
        stripwells.each do |sw|
	        check "Label a new stripwell with the id #{sw}."
	        check "Pipette 40 µL of molecular grade water into wells " + sw.non_empty_string + "."
	        check "Pipette 10 µL each well of supernatant of the spundown stripwell with id #{sw} into each well of the new stripwell"
	        check "Dispose the spundown stripwell with id #{sw}"
	        separator
        end
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

    io_hash[:lysate_stripwell_ids] = stripwells.collect { |s| s.id }
    io_hash[:yeast_sample_ids] = yeast_samples.collect { |y| y.id }

    return { io_hash: io_hash }
  end

end