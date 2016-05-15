needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"
class Protocol
	include Cloning
	include Standard
	def arguments
	    {
	    	io_hash: {total_media: [70709]}
	    	
	    }
	end

	def fill_array rows, cols, num, val
    	num = 0 if num < 0
    	array = Array.new(rows) { Array.new(cols) { -1 } }
    	(0...num).each { |i|
      		row = (i / cols).floor
      		col = i % cols
      		array[row][col] = val
    	}
    array
  	end # fill_array

	def main
		io_hash = input[:io_hash]
		all_media = [io_hash[:total_media]]
		agar_media = Array.new
		all_media.each do |x|
			made_media = find(:item, id: x)[0]
			if(made_media.object_type.name.include?("Agar"))
				agar_media.push(made_media)
			end
		end

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

			plate_batch = produce new_collection "Agar Plate Batch", 10, 10

			res = -1
			while (res < 0 || res > 100) do
				data = show {
					title "Record number"
					note "Record the number of plates poured."
					get "number", var: "num", label: "Enter a number", default: -1
				}
				res = data[:num]
			end

			
			if(res > 0)
				show {
					title "Wait for plates to solidify."
					note "Wait untill all plates have completely solidified. This should take about 10 minutes."
				}
				
			batch_matrix = fill_array 10, 10, res, find(:sample, name: agar_media[i].sample.name)[0].id
			plate_batch.matrix = batch_matrix
			plate_batch.location = "Media Bay"
			plate_batch.save
			
				show {
					title "Stack and label"
					note "Stack the plates agar side up."
					note "Put a piece of labeling tape on each stack with:" 
					note "'#{plate_batch}, 'initials', and 'date'."
				}
			end

			delete agar_media[i]
		end
		io_hash = {plate_batch_id: plate_batch.id}.merge(io_hash)
		release [plate_batch], interactive: true
		return {io_hash: io_hash}
	end
end
