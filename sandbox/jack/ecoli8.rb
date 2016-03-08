class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
	def main
		
		io_hash = input[:io_hash]
		water = find(:item, id: (io_hash[:water]))[0]
		glycerol = find(:item, id: (io_hash[:glycerol]))[0]
		release([water], interactive: true)

		show {
			title "Decant Supernatant"
			note "When the spin is done, take the 225 mL centrifuge tubes out of the centrifuge and immerse in ice."
			note "Take the ice bucket to the dishwashing station and carefully pour out the supernatant from each tube."
			warning "BE CAREFUL NOT TO DISTURB THE PELLET."
			note "Immerse tube in ice immediately after decanting."
		}

		take [glycerol], interactive: true

		show {
			title "Resuspend Cells In Cold 10% Glycerol"
			note "Carefully pour 100 mL cold 10% glycerol into each 225 mL centrifuge tube."
			note "Shake and vortex until pellet is completely resuspended."
			warning "Immerse the tubes in ice when not actively shaking or vortexing."
			note "Immerse tubes in ice once resuspended."
		}


		show {
			title "Combine Tubes"
			note "Combine the four 225 mL tubes to two tubes by carefully pouring. Each of the two tubes should now have 200 mL."
			note "Shake and vortex until pellet is completely resuspended."
			note "Immerse tubes in ice once combined."
		}

		show {
			title "Centrifuge Tubes"
			note "Set the centrifuge to 2500 rpm for 20 minutes at 4 C."
			note "Move tubes from ice to the centrifuge and press start."
		}

		glycerol.location = "Fridge"
		release([glycerol], interactive: true)
		return {io_hash: io_hash}
	end
end
