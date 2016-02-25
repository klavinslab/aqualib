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
		for i in 0..(agar_media.length - 1)

			take [agar_media[i]], interactive: true

			type = show {
				title "Select option"
				select ["LB + Amp", "LB + Kan"], var: "opt", label: "Choose an option", default: 1
			}

			opt = type[:opt]
			
			show {
				title "Take out antibiotics"
				note opt.include?("Amp")? "Take 8 Amp aliquots from the media fridge." : "Take 4 Kan aliquots from the media fridge."
			}

			show {
				title "Prepare plates"
				note "Lay out ~40 plates on the bench."
			}

			show {
				title "Test temperature of agar"
				note "Test the temperature of the LB Agar by placing your hand on the side of the bottle. Do not proceed until the temperature is ~50 degrees."
			}

			show {
				title "Add antibiotics to agar"
				note "Use the P1000 pipette to add one 1 mL aliquot at a time."
				note "Swirl the agar carefully after adding each aliquot."
			}

			show {
				title "Pour plates"
				note "Carefully pour ~25 mL into each plate. For each plate, pour until the agar completely covers the bottom of the plate."
				note "If there is a large number of buttles in the agar, a small amount of ethanol can be used to pop the bubbles."
			}

			res = -1
			while (res < 1 || res > 100) do
				data = show {
					title "Record number"
					note "Record the number of plates poured."
					get "number", var: "num", label: "Enter a number", default: -1
				}
				res = data[:num]
			end

			for j in 1..res
				output = produce new_sample opt, of: "Media", as: "Agar Plate"
				output.location = "30 degree incubator"
				output_media.push(output)
			end
			
			show {
				title "Wait for plates to solidify."
				note "Wait untill all plates have completely solidified. This should take about 10 minutes."
			}
			
			show {
				title "Stack and label"
				note "Stack the plates agar side up."
				note "Put a piece of labeling tape on each stack with '#{agar_media[i].sample.name}', 'initials', and 'date'."
			}

			agar_media[i].mark_as_deleted

		end
		
		release(output_media, interactive: true)
		return {io_hash: io_hash}
	end
end
