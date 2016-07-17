class Protocol

    def arguments
        {
            io_hash: {}
        } 
    end

    def main
        io_hash = input[:io_hash]
        tasks = find(:task, { task_prototype: { name: "Yeast YPAD" } }).select { |t| %w[waiting ready].include? t.status }
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
        set_task_status(task_to_run, "done")
        media = task_to_run.simple_spec[:media_type]
        media_name = find(:sample, id: media)[0].name
        quantity = task_to_run.simple_spec[:quantity]
        
        ingredients = []
        
        if(media_name == "YPAD")
            ingredients += [find(:item, { object_type: { name: "Adenine (Adenine hemisulfate)"}})[0]]
            ingredients += [find(:item, { object_type: { name: "Dextrose" } } )[0]]
            ingredients += [find(:item, { object_type: { name: "Bacto Yeast Extract" } } )[0]]
            ingredients += [find(:item, { object_type: { name: "Bacto Tryptone" } } )[0]]
        else
            raise ArgumentError, "Chosen media is not valid"
        end
        
        
        label = media_name 
        
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
		ingredients += [find(:item,{object_type:{name:"Bacto Agar"}})[0]]
	elsif(task_to_run.simple_spec[:media_container] == "200 mL Agar")
		multiplier = 0.25;
		label += " Agar"
		water = 200
		bottle = "250 mL Bottle"
		ingredients += [find(:item,{object_type:{name:"Bacto Agar"}})[0]]
	else
		raise ArgumentError, "Container specified is not valid"
	end

	produced_media = Array.new
	produced_media_id = Array.new
    output_id = ""
	for i in 0..(quantity - 1)
		output = produce new_sample media_name, of: "Media", as: task_to_run.simple_spec[:media_container]
		produced_media.push(output)
		produced_media_id.push(output.id)
        output_id = output_id + ", #{output.id}"
		produced_media[i].location = "Bench"
	end
	
	bottle = [find(:item, object_type: { name: bottle})[0]] * quantity
		
        
        new_total = io_hash.delete(:total_media) { Array.new } + produced_media_id
        io_hash = {type: "yeast", total_media: new_total}.merge(io_hash)

        show {
          title "Make #{label} Media"
          note "Description: Make #{quantity} #{water}mL of #{label}"
        }
       
        take ingredients + bottle, interactive: true

	if(task_to_run.simple_spec[:media_container].include?("800 mL"))
		show {
			title "Add Stir Bar"
			check "Retrieve #{quantity} Medium Magnetic Stir Bar(s) from B1.525 or dishwashing station."
			check "Add the stir bar(s) to the bottle(s)."
		}
	end
	
        show {
          title "Weigh Out Yeast Extract"
          note "Weight out #{8 * multiplier}g of Bacto Yeast Extract and add to each bottle"
        }
        
        show {
        	title "Weigh Out Tryptone"
        	note "Weigh out #{16 * multiplier}g of Bacto Tryptone and add to each bottle"
        }
        
        show {
        	title "Weigh Out Dextrose"
        	note "Weigh out #{16 * multiplier}g of Dextrose and add to each bottle"
        }
        
        show {
        	title "Weigh Out Adenine Sulfate"
        	note "Weigh out #{0.064 * multiplier}g of Adenine sulfate and add to each bottle"
        }

        if(label.include? "Agar") 
        	show {
        		title "Weigh Out Bacto Agar"
        		note "Weigh out #{16 * multiplier}g of Bacto agar and add to each bottle"
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
          note "Label the bottle(s) with #{label}, 'Date', Your initials'"
        }

        release(bottle)
        release(ingredients + produced_media, interactive: true)

        return {io_hash: io_hash, done: finished, has_agar: io_hash.has_key?(:has_agar)? "yes":"no"}


    end

end
