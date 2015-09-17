needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

    include Standard
    include Cloning

    def arguments
        {
     	   io_hash: {},
     	   #Enter the plate ids as a list
     	   plate_ids: [3798,3797,3799],
     	   num_colonies: [1,2,3],
     	   primer_ids: [[2575,2569,2038],[2054,2038],[2575,2569]],
    	   debug_mode: "No",
    	   group: "cloning"
        }
    end

    def main
    	io_hash = input[:io_hash]
   		io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    	if io_hash[:debug_mode].downcase == "yes"
      		def debug
       			true
      		end
   		end
    	# Make sure have the following hash indexes
    	io_hash = { plate_ids: [], num_colonies: [], primer_ids: [], glycerol_stock_ids: [] }.merge io_hash
		aliquot_num = io_hash[:plate_ids].length

		# Title
		show {
			title "Quick Competent E. coli Purpose/Description"
			note "#{io_hash}"
			note "This protocol is to prepare any cell strain for electroporation. It is specifically for strains that are not frequently transformed and for which we do not have freezer stocks, including strains with one plasmid that you'd like to add a second plasmid to or new strains that you haven't tested out yet. Primarily the cells need to be cold (below 4 C) and washed of as many conductive ions as possible to maximize transformation efficiency."
		}

		# Step 1
		# raise errors if inputs are not valid
	    raise "Incorrect inputs, plate_ids and num_colonies must have the same length." if io_hash[:plate_ids].length != io_hash[:num_colonies].length
	    raise "Incorrect inputs, plate_ids and primer_ids must have the same length." if io_hash[:plate_ids].length != io_hash[:primer_ids].length

	    # Parse out plate_ids, num_colonies, initials for plasmid that has marker info entered.
	    info_needed_plate_ids = []
	    plate_ids = io_hash[:plate_ids]
	    num_colonies = io_hash[:num_colonies]
	    primer_ids = io_hash[:primer_ids]
	    io_hash[:plate_ids].each_with_index do |pid,idx|
	     # if find(:item, id: pid)[0].sample.properties["Bacterial Marker"] == ""
	       # info_needed_plate_ids.push pid
	     # else
	        plate_ids.push pid
	        num_colonies.push io_hash[:num_colonies][idx]
	        primer_ids.push io_hash[:primer_ids][idx]
	      #end
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

	    if io_hash[:glycerol_stock_ids].length > 0
	      glycerol_stocks = io_hash[:glycerol_stock_ids].collect { |id| find(:item, id: id)[0] }
	      take glycerol_stocks, interactive: true, method: "boxes"

	      show {
	        title "Inoculation"
	        note "Use 100 µL sterile tips to vigerously scrape the glycerol stock to get a chunk of stock, add into 14 mL tubes according to the following table."
	        table [["Glycerol stock id", "Overnight id"]].concat(glycerol_stocks.collect { |g| g.id }.zip glycerol_overnights.collect { |o| { content: o.id, check: true } })
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

	    # TEMP
	    show {
	    	title "Create overnight cultures"
	    	note "WIP!"
	    }

		# Step 2
		show {
			title "Incubate"
			check "Inoculate cell culture or colony in 3-5 mL growth media (generally LB)."
			check "Incubate overnight in 37 C shaker."
		}

		# Step 3
		show {
			title "Prepare Water"
			check "Place 10-20 mL molecular grade water (in 50 mL conical tube) in -20 C or -80 C freezer."
		}

		# Step Go to Bed
		show {
			title "You're done for today! Come back tomorrow."
		}

		# Step 4
		show {
			title "Dilute culture"
			check "Dilute overnight culture for 1 minute and 50 seconds into #{3 * aliquot_num} mL fresh broth (#{60 * aliquot_num} uL overnight culture)."
			timer initial: { hours: 0, minutes: 1, seconds: 50}
		}

		# Step 5
		show {
			title "Incubate and check OD600"
			check "Incubate at 37 C for 1-3 hours. Check OD600 on Nanodrop after 1 hour. The target OD600 is 0.4-0.6."
			note "Note: Multiply the absorbance value at 600 nm measured by the Nanodrop by a factor of 10 to get OD600."
			timer initial: { hours: 1, minutes: 0, seconds: 0}
		}

		# Step 6
		show {
			title "Add Water"
			check "Place water from freezer in ice bath."
			check "Add 5-10 mL room temperature molecular grade water and shake to cool."
		}

		2.times {
			# Step 7
			show {
				title "Run in Centrifuge"
				check "Pellet cell culture in 1.5 mL tubes (1 mL culture per tube) by running in refrigerated centrifuge (4 C) for 1 minute at 6000 xg."
				timer initial: { hours: 0, minutes: 1, seconds: 0}
			}

			# Step 8
			show {
				title "Resuspend Cells"
				check "Remove supernatant. Add 1 mL ice cold water and resuspend cells."
			}
		}

		# Step 9
		show {
			title "Resuspend Cells"
			check "Resuspend cells in 40 uL ice cold water."
		}

		# Step 10
		show {
			title "Follow electroporation protocol."
		}

		# Step 11 - Profit!
	end
end
