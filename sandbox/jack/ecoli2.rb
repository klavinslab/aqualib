class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end	
	
	def main

		io_hash = input[:io_hash]
		flask = find(:item, object_type: { name: "125 mL baffled flask"})[0]
		lb_liquid = find(:item, object_type: { name: "800 mL LB liquid (sterile)"})[0]
		stock = find(:item, { sample: { name: "DH5alpha"}, object_type: { name: "Agar Plate" }})[0]
		
		take [flask, lb_liquid], interactive: true
		dh5alpha = produce new_sample "DH5alpha", of: "E coli strain", as: "Overnight Suspension"
		dh5alpha.location = "37 degree shaker"
		io_hash = {dh5alpha: dh5alpha.id}.merge(io_hash)
		
		show {
			title "Label Baffled Flask"	
			note "Label the flask 'DH5alpha', #{dh5alpha.id}, initials, and date"
		}
		
		show {
			title "Add LB Liquid"
			note "Using the serological pipette, add 25 mL LB liquid to the baffled flask"
		}

		show {
			title "Go to -80 freezer"
			note "Bring Eppendorf tube rack, P100 pipette, and P100 pipette tips"  
		}
		
		take [stock], interactive: true

		show {
			title "Glycerol stock scrape, and add to media: QUICKLY"
			note "Put glycerol stock in tube rack, loosen cap"
			note "Take lid off flask"
			note "Put tip on pipette"
			note "Leaving glycerol stock in rack, take off cryotube lid, scrape a large chunk from glycerol stock, and replace cryotube lid"
			note "Carefully scrape glycerol into flask of LB by tipping flask and swirling tip into media"
			note "Discard tip"
			note "Put the lid back on the flask"
		}
		
		release([stock], interactive: true)
		
		show {
			title "Clean up"
			note "Take pipette, tips back to bench"
		}
		
		release([flask])
		release([dh5alpha, lb_liquid], interactive: true)
		
		return { io_hash: io_hash }
		
		

	end
end
