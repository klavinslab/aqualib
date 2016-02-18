class Protocol

	def arguments
	    {
	    	io_hash: {}
	    }
	end

	def main
		io_hash = input[:io_hash]
		tasks = find(:task,{ task_prototype: { name: "Bacteria Media" } }).select { |t| %w[waiting ready].include? t.status }

		data = show {
			title "Choose which task to run"
			select tasks.collect { |t| t.name }, var: "choice", label: "Choose the task you want to run"
		}

		task_to_run = tasks.select { |t| t.name == data[:choice] }[0]
		# show {
		#  	note task_to_run.name
		#  	note task_to_run.id
		#  	note task_to_run.to_json
		# 	note task_to_run.simple_spec[:media_type]
		# }
		media = task_to_run.simple_spec[:media_type]
		set_task_status(task_to_run, "done")
		media_name = find(:sample, id: media)[0].name
		quantity = task_to_run.simple_spec[:quantity]
		if(media_name == "LB") 
			label = "LB Liquid Media"
			ingredient = find(:item,{object_type:{name:"Difco LB Broth, Miller"}})[0]
			amount = 20;
		elsif(media_name == "TB") 
			label = "TB Liquid Media"
			ingredient = find(:item,{object_type:{name:"Terrific Broth, modified"}})[0]
			amount = 20;
		else
			raise ArgumentError, "Chosen media is not valid"
		end
		
		if(task_to_run.simple_spec[:media_container] == "800 mL Bottle") 
			multiplier = 1;
			water = 800
		elsif(task_to_run.simple_spec[:media_container] == "Agar Plate")
			multiplier = 1;
			amount += 9.6
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

		produced_media = Array.new
		for i in 0..(quantity - 1)
			produced_media.push(produce new_sample media_name, of: "Media", as: task_to_run.simple_spec[:media_container])
			produced_media[i].location = "Bench"
		end
		bottle = [find(:item, object_type: { name: "1 L Bottle"})[0]] * quantity
		take [ingredient] + bottle, interactive: true
		#produced_media.location = "Bench"
		io_hash = {type: "bacteria"}.merge(io_hash)
		show {
			title "#{label}"
			note "Description: This prepares #{quantity} bottle(s) of #{label} for growing bacteria"
		}
		
		show {
			title "Get Bottle and Stir Bar"
			note "Retrieve one Glass #{quantity} Bottle(s) from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
		}
		
		show {
			title "Weigh Out Powder"
			note "Using the gram scale, large weigh boat, and chemical spatula, weigh out #{quantity} - #{amount * multiplier} grams of '#{ingredient.object_type.name}' powder and pour into each bottle."
			warning "Before and after using the spatula, clean with ethanol"
		}
		
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
		release([ingredient] + produced_media, interactive: true)
		return {io_hash: io_hash}
	end
end
