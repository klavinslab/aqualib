class Protocol

	def arguments
	    {
	    	io_hash: {}
	    }
	end

  def main
	
	io_hash = input[:io_hash]
	plates = Array.new
	io_hash[:agar_plate_ids].each do |i|
		sing_plate = find(:item, id: i)[0]
		sing_plate.location = "Media Fridge"
		plates.push(sing_plate)
	end
	
	take plates, interactive: true
	
	show {
		title "Move Plates To Storage Containers"
		note "Find an empty storage container on top of the media fridge."
		note "Remove any labeling tape that might be on the container."
		note "Move one of the labels on the plate stack to the front of the storage container."
		note "Move plates #{io_hash[:agar_plate_ids].join(", ")} to the storage container."
	}
	
	release(plates, interactive: true)
	return {io_hash: io_hash}

  end
end
