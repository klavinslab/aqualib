class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
	def main
		
		io_hash = input[:io_hash]
		water = find(:item, id: (io_hash[:water]))[0]

		show {
			title "Centrifuge Tubes"
			note "Confirm that temperature is at 4C"
			note "Confirm that the correct centrifuge tube holders are in the centrifuge."
			note "Set the speed to 2500 rpm and the time to 15 minutes."
			note "Move 225 mL tubes with culture from ice to the centrifuge and press start."
		}

		show {
			title "Decant Supernatant"
			note "When the spin is done, take the 225 mL centrifuge tubes out of the centrifuge and immerse in ice."
			note "Take the ice bucket to the dishwashing station and carefully pour out the supernatant from each tube."
			note "Immerse tube in ice immediately after decanting."
		}

		take [water], interactive: true

		show {
			title "Resuspend Cells in Cold DI Water"
			note "Carefully pour 200 mL cold, sterile DI water into each 225 mL centrifuge tube."
			note "Shake and vortex until pellet is completely resuspended."
			warning "Immerse the tubes in ice when not actively shaking or vortexing."
			note "Immerse all tubes in ice once resuspended."
		}

		show {
			title "Centrifuge Tubes"
			note "Set the centrifuge to 2500 rpm for 20 minutes at 4 C."
			note "Move 225 mL tubes from ice to centrifuge and press start."
		}

		water.location = "Dishwashing station"
		return {io_hash: io_hash}
	end
end
