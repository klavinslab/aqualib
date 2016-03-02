class Protocol

	def arguments
	    {
	    	io_hash: {}
	    }
	end

  def main
	
	io_hash = input[:io_hash]
	#plates = Array.new
	diff_plates = Hash.new
	io_hash[:agar_plate_ids].each do |i|
		sing_plate = find(:item, id: i)[0]
		#plates.push(sing_plate)
		if(diff_plates.has_key?(sing_plate.sample.name))
			array_temp = diff_plates(sing_plate.sample.name)
			array_temp.push(sing_plate)
			diff_plates = diff_plates.merge({sing_plate.sample.name: array_temp})
		else
			diff_plates = diff_plates.merge({sing_plate.sample.name: [sing_plate]})
		end
	end
	
	diff_plates.each { |key, value|
		
		take value, interactive: true
		ids = Array.new
		value.each do |i|
			ids.push(i.id)
		end
		show {
			title "Move Plates To Storage Containers"
			note "Find an empty storage container on top of the media fridge."
			note "Remove any labeling tape that might be on the container."
			note "Move one of the labels on the plate stack to the front of the storage container."
			note "Move plates #{ids.join(", ")} to the storage container."
		}
		
		value.each do |i|
			i.location = "Media Fridge"
		end
		
		release(value, interactive: true)
	}
	return {io_hash: io_hash}

  end
end
