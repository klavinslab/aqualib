class Protocol

    def arguments
        {
            io_hash: {}
        }
    end

    def main
        io_hash = input[:io_hash]
        tasks = find(:task, {task_prototype: {name: "Yeast SDO or SC"} }).select { |t| %w[waiting ready].include? t.status }
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
            #produced_media = produce new_sample "SC", of: "Media", as: "800 mL Bottle"
            present_acid = acid_bank

        elsif(media_name == "SDO")
            #produced_media = produce new_sample "SDO", of: "Media", as: "800 mL Bottle"
            present_acid = []

        else
            #produced_media = produce new_sample media_name, of: "Media", as: "800 mL Bottle"
            present_acid = acid_bank - media_ingredients
        end
        
        if(task_to_run.simple_spec[:media_container] == "800 mL Bottle") 
		multiplier = 1;
		water = 800
	elsif(task_to_run.simple_spec[:media_container] == "Agar Plate")
		multiplier = 1;
		label += " for Agar"
		water = 800
	elsif(task_to_run.simple_spec[:media_container] == "400 mL Bottle")
		multiplier = 0.5;
		water = 400
	elsif(task_to_run.simple_spec[:media_container] == "200 mL Bottle")
		multiplier = 0.25;
		water = 200
	else
		raise ArgumentError, "Container specified is not valid"
	end
        
	present_acid.each do |i|
		if(i == "Leu")
		    ingredients += [find(:item,{object_type:{name:"Leucine Solution"}})[0]]
		elsif(i == "His")
		    ingredients += [find(:item,{object_type:{name:"Histidine Solution"}})[0]]
		elsif(i == "Trp")
		    ingredients += [find(:item,{object_type:{name:"Tryptophan Solution"}})[0]]
		else
		    ingredients += [find(:item,{object_type:{name:"Uracil Solution"}})[0]]
		end
	end     
	
	produced_media = Array.new
	for i in 0..(quantity - 1)
		produced_media.push(produce new_sample media_name, of: "Media", as: task_to_run.simple_spec[:media_container])
		produced_media[i].location = "Bench"
	end
        
	#produced_media.location = "Bench"
	io_hash = {type: "yeast"}.merge(io_hash)

        bottle = [find(:item, object_type: { name: "1 L Bottle"})[0]] * quantity
        ingredients += [find(:item,{object_type:{name:"Adenine (Adenine hemisulfate)"}})[0]]
        ingredients += [find(:item,{object_type:{name:"Dextrose"}})[0]]
        ingredients += [find(:item,{object_type:{name:"Yeast Nitrogen Base Without Amino Acids"}})[0]]
        ingredients += [find(:item, {object_type:{name:"Yeast Synthetic Drop-out Medium Supplements"}})[0]]
        take bottle + ingredients, interactive: true

        show {
            title label
            note "Description: Makes #{quantity} ${water} mL of #{label} media with 2% glucose and adenine supplement"
        }

        show {
            title "Get Bottle and Stir Bar"
            note "Retrieve #{quantity} Glass 1L Bottle(s) from the glassware rack and #{quantity} Medium Magnetic Stir Bar(s) from the dishwashing station, bring to weigh station. Put the stir bar(s) in the bottle(s)."
        }

        show {
            title "Weigh Chemicals"
            note "Weigh out #{5.36 * multiplier}g nitrogen base, #{1.12 * multiplier}g of DO media, #{16 * multiplier}g of dextrose, #{0.064 * multiplier}g adenine sulfate and add to each bottle"
        }

	if(media_name != "SDO")
	        show {
	            title "Add Amino Acid(s)"
	            note "Add #{8 * multiplier} mL of #{present_acid.join(", ")} solutions each to each bottle(s)"
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
            title "Cap Bottle"
            note "Place cap(s) on bottle(s) loosely"
        }

        show {
            title "Label Bottle"
            note "Label the bottle(s) with '#{media_name}', 'Date', 'Your initials'"
        }
        release (bottle)
        release(ingredients + produced_media, interactive: true)
        return {io_hash: io_hash}
    end
end
