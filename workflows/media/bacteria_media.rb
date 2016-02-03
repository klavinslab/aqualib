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
		# 	note task_to_run.name
		# 	note task_to_run.id
		# 	note task_to_run.to_json
		# 	note task_to_run.simple_spec[:media_type]
		# }
		media = task_to_run.simple_spec[:media_type]
		set_task_status(task_to_run, "done")
		# media = data[:choice]
		if(media == 11762)
			ingredient = find(:item,{object_type:{name:"Difco LB Broth, Miller"}})[0]
			if(task_to_run.simple_spec[:media_container] == "800 mL Bottle") 
				amount = 20
				label = "LB Liquid Media"
				produced_media = produce new_sample "LB", of: "Media", as: "800 mL Bottle"
			elsif(task_to_run.simple_spec[:media] == "Agar Plate")
				amount = 29.6
				label = "LB Agar"
				produced_media = produce new_sample "LB", of: "Media", as: "Agar Plate"
			else
				raise ArgumentError, "Container specified is not valid"
			end
		elsif(media == 11763)
			if(task_to_run.simple_spec[:media_container] == "800 mL Bottle")
				amount = 20
				label = "TB Liquid Media"
				ingredient = find(:item,{object_type:{name:"Terrific Broth, modified"}})[0]
				produced_media = produce new_sample "TB", of: "Media", as: "800 mL Bottle"
			else
				raise ArgumentError, "Container specified is not valid"
			end
		else
			raise ArgumentError, "User input is not valid"
		end

		bottle = find(:item, object_type: { name: "1 L Bottle"})[0]
		take [ingredient, bottle], interactive: true
		produced_media.location = "Bench"
		# bottle.mark_as_deleted
		io_hash = {media: produced_media}.merge(io_hash)
		show {
			title "#{label}"
			note "Description: This prepares a bottle of #{label} for growing bacteria"
		}
		
		show {
			title "Get Bottle and Stir Bar"
			note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
		}
		
		show {
			title "Weigh Out Powder"
			note "Using the gram scale, large weigh boat, and chemical spatula, weigh out #{amount} grams of '#{ingredient.object_type.name}' powder and pour into the bottle."
			warning "Before and after using the spatula, clean with ethanol"
		}
		
		show {
			title "Measure Water"
			note "Take the bottle to the DI water carboy and add water up to the 800 mL mark"
		}
		
		show {
			title "Mix solution"
			note "Shake until most of the powder is dissolved."
			note "It is ok if a small amount of powder is not dissolved because the autoclave will dissolve it"
		}
		
		show {
			title "Label Media"
			note "Label the bottle with '#{label}', 'Your initials', and 'date'"
		}
		release([bottle])
		release([ingredient, produced_media], interactive: true)
		return {io_hash: io_hash}
	end
end
