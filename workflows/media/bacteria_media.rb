class Protocol

	def arguments
	    {
	    	io_hash: {}
	    }
	end

	def main
		io_hash = input[:io_hash]
		tasks = find(:task,{ task_prototype: { name: "Bacteria Media" } }).select { |t| %w[waiting ready].include? t.status }
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
		ingredient = []
		if(media_name == "LB") 
			if(task_to_run.simple_spec[:media_container].include?("Agar"))
				label = "LB Agar"
				ingredient = [find(:item, {object_type:{name:"LB Agar Miller"}})[0]]
	        		io_hash = {has_agar: "yes"}.merge(io_hash)
			else 
				label = "LB Liquid Media"
				ingredient = [find(:item,{object_type:{name:"Difco LB Broth, Miller"}})[0]]
			end
			amount = 20
		elsif(media_name == "TB") 
			label = "TB Liquid Media"
			ingredient = [find(:item,{object_type:{name:"Terrific Broth, modified"}})[0]]
			amount = 38.08
			ingredient += [find(:item, {sample: { name: "50% Glycerol" }, object_type: { name: "800 mL Liquid" }})[0]]
			find(:item, { sample: { name: "pLAB1" }, object_type: { name: "Plasmid Stock" } } )
		else
			raise ArgumentError, "Chosen media is not valid"
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
			amount += 9.6
			water = 800
			bottle = "1 L Bottle"
		elsif(task_to_run.simple_spec[:media_container] == "400 mL Agar")
			multiplier = 0.5;
			amount += 9.6
			water = 400
			bottle = "500 mL Bottle"
		elsif(task_to_run.simple_spec[:media_container] == "200 mL Agar")
			multiplier = 0.25;
			amount += 9.6
			water = 200
			bottle = "250 mL Bottle"
		else
			raise ArgumentError, "Container specified is not valid"
		end

		produced_media_id = Array.new
		produced_media = Array.new
		for i in 0..(quantity - 1)
			output = produce new_sample media_name, of: "Media", as: task_to_run.simple_spec[:media_container]
			produced_media.push(output)
			produced_media[i].location = "Bench"
			produced_media_id.push(output.id)
		end
		bottle = [find(:item, object_type: { name: bottle})[0]] * quantity
		show {
			title "#{label}"
			note "Description: This prepares #{quantity} bottle(s) of #{label} for growing bacteria"
		}
		take ingredient + bottle, interactive: true
	        new_total = io_hash.delete(:total_media) { Array.new } + produced_media_id
	        io_hash = {type: "bacteria", total_media: new_total}.merge(io_hash)
		
		show {
			title "Add Stir Bar"
			check "Retrieve #{quantity} Medium Magnetic Stir Bar(s) from B1.525 or dishwashing station."
			check "Add the stir bar(s) to the bottle(s)."
		}
		
		show {
			title "Weigh Out Powder"
			note "Using the gram scale, large weigh boat, and chemical spatula, weigh out #{amount * multiplier} grams of '#{ingredient[0].object_type.name}' powder and pour into each bottle."
			warning "Before and after using the spatula, clean with ethanol"
		}
		
		if(label.include?"TB") 
			show {
				title "Add Glycerol"
				note "Using the serological pipette, add #{12.8 * multiplier} mL of 50% glycerol to the bottle."
			}
		end
		
		show {
			title "Measure Water"
			note "Take the bottle to the DI water carboy and add water up to the #{water} mL mark"
		}
		
		show {
			title "Mix solution"
			note "Shake until most of the powder is dissolved."
			note "It is ok if a small amount of powder is not dissolved because the autoclave will dissolve it"
		}
		
		show {
			title "Label Media"
			note "Label the bottle(s) with '#{label}', 'Your initials', and 'date'"
		}
		release(bottle)
		release(ingredient + produced_media, interactive: true)
		return {io_hash: io_hash, done: finished, has_agar: io_hash.has_key?(:has_agar)? "yes":"no"}
	end
end
