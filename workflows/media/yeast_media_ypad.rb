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
        
        if(media_name == "YPAD")
            adenine = find(:item, { object_type: { name: "Adenine (Adenine hemisulfate)" } } )[0] 
            dextrose = find(:item, { object_type: { name: "Dextrose" } } )[0] 
            bacto = find(:item, { object_type: { name: "Bacto Yeast Extract" } } )[0] 
            tryp = find(:item, { object_type: { name: "Bacto Tryptone" } } )[0]
        else
            raise ArgumentError, "Chosen media is not valid"
        end
        
        bottle = [find(:item, object_type: { name: "1 L Bottle"})[0]] * quantity
        
        label = media_name 
        
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
        
		produced_media = Array.new
		produced_media_id = Array.new
		for i in 0..(quantity - 1)
			output = produce new_sample media_name, of: "Media", as: task_to_run.simple_spec[:media_container]
			produced_media.push(output)
			produced_media_id.push(output.id)
			produced_media[i].location = "Bench"
		end
		
        take [adenine, dextrose, bacto, tryp] + bottle, interactive: true
        
        new_total = io_hash.fetch(:total_media, Array.new) + produced_media_id
        io_hash = {type: "yeast", total_media: new_total}.merge(io_hash)
        show {
        	note io_hash[:total_media]
        }

        show {
          title "Make YPAD Media"
          note "Description: Make #{quantity} #{water}mL of yeast extract-tryptone-dextrose medium + adenine (YPAD)"
        }

        show {
          title "Weigh Chemicals"
          note "Weight out #{8 * multiplier}g yeast extract, #{16 * multiplier}g tryptone, #{16 * multiplier}g dextrose, #{0.064 * multiplier}g adenine sulfate and add to 1000 mL bottle(s)"
        }

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
          title "Label Bottle(s)"
          note "Label the bottle(s) with 'YPAD', 'Date', Your initials'"
        }

        release(bottle)
        release([adenine, dextrose, bacto, tryp] + produced_media, interactive: true)

        return {io_hash: io_hash, done: finished}


    end

end
