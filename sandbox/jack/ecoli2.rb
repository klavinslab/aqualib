class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end	
	
	def main

		io_hash = input[:io_hash]
		flask = find(:item, object_type: { name: "125 mL baffled flask"})[0]
		stock = find(:item, sample: { object_type: { name: "E coli Glycerol Stock" }, sample: { name: "DH5alpha"}})
		
		take [flask, stock], interactive: true
		#dh5alpha = produce new_sample "DH5alpha", of: "E coli strains", as: "E coli Glycerol Stocks"
		#d5alpha.location = "37 shaker"
		#io_hash = {dh5alpha: dh5alpha}.merge(io_hash)
		#flask.mark_as_deleted
		
		show {
			title "Label Baffled Flask"	
			#note "Label the flask 'DH5alpha', #{dh5alpha.id}, initials, and date"
		}
		
		show {
			title "Add LB Liquid"
			note "Using the serological pipette, add 25 mL LB liquid to the baffled flask"
		}

		show {
			title "Go to -80 freezer"
			note "Bring Eppendorf tube rack, P100 pipette, and P100 pipette tips"  
		}

		show {
			title "Glycerol stock scrape, and add to media: QUICKLY"
			note "Put glycerol stock in tube rack, loosen cap"
			note "Take lid off flask"
			note "Put tip on pipette"
			note "Leaving glycerol stock in rack, take off cryotube lid, scrape a large chunk from glycerol stock, and replace cryotube lid"
			note "Carefully scrape glycerol into flask of LB by tipping flask and swirling tip into media"
			note "Discard tip"
			note "Put the lid back on the flask"
			note "Return glycerol stock"
		}
		
		release([stock], interactive: true)
		
		show {
			title "Clean up"
			note "Take pipette, tips back to bench"
		}
		
		#release([d5alpha], interactive: true) {
		#	note "Place flask in 37 shaker"
		#}
		
		

	end
end
