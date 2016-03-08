class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
	def main
		
		io_hash = input[:io_hash]
		flask2000 = find(:item, id: (io_hash[:dh5alpha_new]))[0]

		show {
			title "Get Ice"
			note "Walk to the ice machine room on the second floor in Bagley with a large red bucket and full the bucket 3/4 full with ice."
			note "If unable to go to Bagley, use ice cubes to make a water bath (of mostly ice) or use the chilled aluminum bead bucket (if using aluminum bead bucket, place it back in the freezer between spins)"
		}

		show {
			title "Get Tubes"
			note "Get the (4) 225 mL tubes from the freezer"
		}

		show {
			title "Immerse tubes"
			note "Immerse the 225 mL tubes in ice"
		}

		take [flask2000], interactive: true

		show {
			title "Transfer Culture to 225 mL Centrifuge Tubes"
			note "Carefully pour 200 mL of culture into each centrifuge tube, keeping the tubes immerse in ice as long as possible."
		}

		flask2000.location = "Dishwashing station"
		release([flask2000], interactive: true)
		return {io_hash: io_hash}
	end
end
