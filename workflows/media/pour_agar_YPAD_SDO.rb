class Protocol

	def arguments
	    {
	    	io_hash: {}
	    }
	end

	def main
		io_hash = input[:io_hash]
		all_media = io_hash[:total_media]
		agar_media = Array.new
		output_media = Array.new
		all_media.each do |x|
			made_media = find(:item, id: x)[0]
			if(made_media.object_type.name.include?("Agar"))
				agar_media.push(made_media)
			end
		end
		counter = 0
		agar_plate_ids = Array.new
		for i in 0..(agar_media.length - 1)

			take [agar_media[i]], interactive: true

			show {
				title "Prepare plates"
				note "Lay out ~40 plates on the bench."
			}
			
			show {
				title "Pour plates"
				note "Carefully pour ~25 mL into each plate. For each plate, pour until the agar completely covers the bottom of the plate."
				note "If there is a large number of bubbles in the agar, a small amount of ethanol can be used to pop the bubbles."
			}

			res = -1
			while (res < 0 || res > 100) do
				data = show {
					title "Record number"
					note "Record the number of plates poured."
					get "number", var: "num", label: "Enter a number", default: -1
				}
				res = data[:num]
			end
			curr_counter = counter
			for j in 1..res
				output = produce new_sample agar_media[i].sample.name, of: "Media", as: "Agar Plate"
				output.location = "30 degree incubator"
				output_media.push(output)
				counter = counter + 1
				agar_plate_ids.push(output.id)
			end
			
			show {
				title "Wait for plates to solidify."
				note "Wait untill all plates have completely solidified. This should take about 10 minutes."
			}
			
			show {
				title "Stack and label"
				note "Stack the plates agar side up."
				note "Put a piece of labeling tape on each stack with:" 
				for k in 0..(res - 1)
					note "'#{agar_media[i].sample.name}', '#{output_media[curr_counter + k].id}', 'initials', and 'date'."
				end
			}

			agar_media[i].mark_as_deleted

		end
		io_hash = {agar_plate_ids: agar_plate_ids}.merge(io_hash)
		release(output_media, interactive: true)
		return {io_hash: io_hash}
	end
end
