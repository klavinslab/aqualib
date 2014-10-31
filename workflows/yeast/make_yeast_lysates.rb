needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
  	{
      io_hash: {},
  		yeast_item_ids: [13011,13010,13022],
  		colony_numbers: [3,3,3],
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

  	show {
  		title "Test page"
  		note "This protocol makes yeast lysates in stripwell tubes"
  	}

  	yeast_items = input[:yeast_item_ids].collect {|yid| find(:item, id: yid )[0]}
  	take yeast_items, interactive: true

  	yeast_lysates = []
  	yeast_colonies = []
  	yeast_items.each_with_index do |y,idx|
  		(1..input[:colony_numbers][idx]).each do |x|
  			yeast_lysates.push y.sample
  			yeast_colonies.push y
  		end
  	end

  	sds = yeast_lysates.length * 3 * 1.1
  	water = yeast_lysates.length * 27 * 1.1

  	show {
  		title "Prepare 0.2 percent SDS"
  		check "Grab a 2 percent SDS stock."
  		check "Grab an empty 1.5 mL tube, label as 0.2 percent SDS."
  		check "Pipette #{sds.round(1)} µL of 2 percent SDS stock into the 1.5 mL tube."
  		check "Pipette #{water.round(1)} µL of molecular grade water into the 1.5 mL tube."
  		check "Mix with vortexer."
  	}

  	stripwells = produce spread yeast_lysates, "Stripwell", 1, 12

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
    	note "Before scraping colony, mark it with stripwell_id/location. For example, the first one should be marked as #{stripwells[0].id}/#{1}"
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
      check "Press 'run' and select 50 µL."
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

    io_hash[:stripwell_ids] = stripwells.collect { |s| s.id }
    io_hash[:yeast_lysate_ids] = yeast_lysates.collect { |y| y.id }

    return { io_hash: io_hash }
  end

end