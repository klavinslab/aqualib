class Protocol

    def arguments
        {
            io_hash: {}
        }
    end

    def main
        io_hash = input[:io_hash]
        tasks = find(:task, {task_prototype: {name: "Yeast SDO or SC"} }).select { |t| %w[waiting ready].include? t.status }
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
        quantity = task_to_run.simple_spec[:quantity]
        set_task_status(task_to_run, "done")
        media_name = find(:sample, id: media)[0].name
        media_ingredients = media_name.split(" -").drop(1)
        acid_bank = ["His", "Leu", "Ura", "Trp"]
        ingredients = []
        label = media_name
        if(media_name == "SC")
            present_acid = acid_bank

        elsif(media_name == "SDO")
            present_acid = []

        else
            present_acid = acid_bank - media_ingredients
        end
        
        if(task_to_run.simple_spec[:media_container] == "800 mL Liquid") 
		multiplier = 1;
		water = 800
		bottle = "1 L Bottle"
	elsif(task_to_run.simple_spec[:media_container] == "400 mL Liquid")
		multiplier = 0.5;
		water = 400
		bottle = "500 mL Bottle"
	elsif(task_to_run.simple_spec[:media_container] == "200 mL Liquid")
		multiplier = 0.25;
		water = 200
		bottle = "250 mL Bottle"
        elsif(task_to_run.simple_spec[:media_container] == "800 mL Agar") 
		multiplier = 1;
		label += " Agar"
		water = 800
		bottle = "1 L Bottle"
	        io_hash = {has_agar: "yes"}.merge(io_hash)
		ingredients += [find(:item,{object_type:{name:"Bacto Agar"}})[0]]
	elsif(task_to_run.simple_spec[:media_container] == "400 mL Agar")
		multiplier = 0.5;
		label += " Agar"
		water = 400
		bottle = "500 mL Bottle"
	        io_hash = {has_agar: "yes"}.merge(io_hash)
		ingredients += [find(:item,{object_type:{name:"Bacto Agar"}})[0]]
	elsif(task_to_run.simple_spec[:media_container] == "200 mL Agar")
		multiplier = 0.25;
		label += " Agar"
		water = 200
		bottle = "250 mL Bottle"
	        io_hash = {has_agar: "yes"}.merge(io_hash)
		ingredients += [find(:item,{object_type:{name:"Bacto Agar"}})[0]]
	else
		raise ArgumentError, "Container specified is not valid"
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
	
	produced_media_id = Array.new	
	produced_media = Array.new
	for i in 0..(quantity - 1)
		output = produce new_sample media_name, of: "Media", as: task_to_run.simple_spec[:media_container]
		produced_media.push(output)
		produced_media[i].location = "Bench"
		produced_media_id.push(output.id)
	end
        
        new_total = io_hash.delete(:total_media) { Array.new } + produced_media_id
        io_hash = {type: "yeast", total_media: new_total}.merge(io_hash)

        bottle = [find(:item, object_type: { name: bottle})[0]] * quantity
        ingredients += [find(:item,{object_type:{name:"Adenine (Adenine hemisulfate)"}})[0]]
        ingredients += [find(:item,{object_type:{name:"Dextrose"}})[0]]
        ingredients += [find(:item,{object_type:{name:"Yeast Nitrogen Base Without Amino Acids"}})[0]]
        ingredients += [find(:item, {object_type:{name:"Yeast Synthetic Drop-out Medium Supplements"}})[0]]

        show {
            title label
            note "Description: Makes #{quantity} #{water} mL of #{label} media"
        }
        
        take bottle + ingredients, interactive: true
        take acid_solutions, interactive: true
        
	show {
		title "Add Stir Bar"
		check "Retrieve #{quantity} Medium Magnetic Stir Bar(s) from B1.525 or dishwashing station."
		check "Add the stir bar(s) to the bottle(s)."
	}

        show {
            title "Weigh Nitrogen Base"
            note "Weigh out #{5.36 * multiplier}g nitrogen base and add to each bottle"
        }
        
        show {
       		title "Weigh Out DO Media"
       		note "Weigh out #{1.12 * multiplier}g of DO media and add to each bottle"
        }
        
        show {
        	title "Weigh Out Dextrose"
        	note "Weigh out #{16 * multiplier}g of dextrose and add to each bottle"
        }
        
        show {
        	title "Weigh Out Adenine Sulfate"
        	note "Weigh out #{0.064 * multiplier}g of adenine sulfate and add to each bottle"
        }
        
        if(label.include? "Agar") 
        	show {
        		title "Weigh Out Bacto Agar"
        		note "Weigh out #{16 * multiplier}g of bacto agar and add to each bottle"
        	}
        end

	if(media_name != "SDO")
	        show {
	            title "Add Amino Acid(s)"
	            note "Add #{8 * multiplier} mL of each solution to each bottle(s):"
	            present_acid.each do |i|
	            	check i
	            end
	            #note "Add #{8 * multiplier} mL of #{present_acid.join(", ")} solutions each to each bottle(s)"
	        }
	end

        show {
            title "Measure Water"
            note "Take the bottle(s) to the DI water carboy and add water up to the #{water} mL mark"
        }

        show {
            title "Mix solution"
            note "Shake until most of the powder is dissolved."
            note "It is ok if a small amount of powder is not dissolved because the autoclave will dissolve it"
        }


        show {
            title "Label Bottle"
            note "Label the bottle(s) with '#{label}', 'Date', 'Your initials'"
        }
        release (bottle)
        release(ingredients + produced_media, interactive: true)
        return {io_hash: io_hash, done: finished, has_agar: io_hash.has_key?(:has_agar)? "yes":"no"}
    end
end
