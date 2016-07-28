needs "aqualib/lib/standard/"
needs "aqualib/lib/cloning"

class Protocol
	include Standard
	include Cloning

	def arguments {
		io_hash: {},

	}

	def main {
		io_hash = input[:io_hash]
		tasks = find(:task,{ task_prototype: { name: "Warming Agar" } }).select { |t| %w[waiting ready].include? t.status }
		if(tasks.length == 1)
			finished = "yes"
		else
			finished = "no"
		end
		data = show {
			title "Choose which task to run"
			select tasks.collect { |t| t.name }, var: "choice", label: "Choose the task you want to run"
		}

		task_to_run = tasks.select { |t| t.name == data[:choice] }[0]
		media = task_to_run.simple_spec[:media_type]
		set_task_status(task_to_run, "done")
		media_name = find(:sample, id: media)[0].name
		quantity = task_to_run.simple_spec[:quantity]
		media_ingredients = media_name.split("-").drop(1)
		acid_bank = ["His", "Trp", "Leu", "Ura"]
		present_acid = acid_bank - media_ingredients
		container = task_to_run.simple_spec[:media_container]

		if container.include?("800 mL")
			multiplier = 1
		elsif container.include?("400 mL")
			multiplier = 0.5
		elsif container.include?("200 mL")
			multiplier = 0.5
		end

	acid_solutions = Array.new    
	present_acid.each do |i|
		if(i == "Leu")
		    acid_solutions += [find(:item,{object_type:{name:"Leucine Solution"}})[0]]
		elsif(i == "His")
		    acid_solutions += [find(:item,{object_type:{name:"Histidine Solution"}})[0]]
		elsif(i == "Trp")
		    acid_solutions += [find(:item,{object_type:{name:"Tryptophan Solution"}})[0]]
		else
		    acid_solutions += [find(:item,{object_type:{name:"Uracil Solution"}})[0]]
		end
	end

	agar = [find(:item, object_type: { name: container }, id: 11768)[0]] * quantity
	if acid_solutions.present?
		agar = [agar] + [acid_solutions]
	end
	take agar, interactive: true

	show{
		title "Microwave SDO Agar"
		note "Microwave the SDO Agar at 70\% power for 2 minutes until all the agar is dissolved."
	}

	show{
		title "Add Amino Acids"
		note "Add #{multiplier * 8} mL of the following solution to each bottle(s):"
		acid_solutions.each do |i|
			check i
		end
	}

	show{
		title "Prepare Plates"
		note "Lay out approximately #{multiplier * 32} plates on the bench"
	}

	show{
		title "Pour Plates"
		note "Carefully pour ~25 mL into each plate. For each plate, pour until the agar completely covers the bottom of the plate."
		note "If there are a large number of bubbles in the agar, use a small amount of ethanol to pop them."
	}
	data = show{
		title "Record Number"
		note "Record the number of plates poured."
		get "number", var: "plates_poured", label: "Please record the number of plates.", default: 0
	}

	num = data[:plates_poured]

	batch_matrix = fill_array 10, 10, num, media_type
    plate_batch.matrix = batch_matrix
    plate_batch.location = "30 C incubator"
    plate_batch.save

    show{
    	title "Wait For Plates to Solidify"
    	note "Wait until all plates have completely solidified. This should take about 10 minutes."
    }

    show{
    	title "Stack and Label"
    	note "Stack the plates agar side up."
    	note "Put a piece of labeling tape on each stack with #{media_name}, #{plate_batch}, 'your initials', and 'date'."
    }

    release [plate_batch], interactive: true
    return { io_hash: io_hash }
	}
end

	
