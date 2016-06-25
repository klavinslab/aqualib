class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
	def main
		
		io_hash = input[:io_hash]
		glycerol = find(:item, id: (io_hash[:glycerol]))[0]

		show {
			title "Decant Supernatant"
			note "When the spin is done, take the 225 mL centrifuge tubes out of the centrifuge and immerse in ice."
			note "Take the ice bucket to the dishwashing station and carefully pour out the supernatant from each tube."
			warning "BE CAREFUL NOT TO DISTURB THE PELLET."
			note "Immerse tube in ice immediately after decanting."
		}

		take [glycerol], interactive: true

		show {
			title "Resuspend In Cold 10% Glycerol"
			note "Using a serological pipette, add 8 mL of cold 10% glycerol to each of the two 225 mL centrifuge tubes."
			note "Shake and vortex until pellet is completely resuspended."
			warning "Immerse the tubes in ice when not actively shaking or vortexing."
			note "Immerse tubes in ice once resuspended."
		}


		show {
			title "Combine Tubes"
			note "Combine the two 225 mL tubes to one tube by carefully pouring."
			note "Immerse tube in ice once combined."
		}

		show {
			title "Centrifuge Tubes"
			note "Set the centrifuge to 2500 rpm for 20 minutes at 4 C."
			note "Take an empty 225 mL centrifuge tube and add ~40 mL water to use as a balance. Verify that the balance tube and resuspended cells have the same volume."
			note "Move the tube from the ice and balance tube to the centrifuge and press start."
		}

		glycerol.location = "Dishwashing station"
		release([glycerol], interactive: true)
		return {io_hash: io_hash}
	end
end
