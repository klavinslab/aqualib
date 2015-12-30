class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end	
	
	def main

		io_hash = input[:io_hash]
		flask = find(:item, object_type: { name: "125 mL baffled flask"})[0]
		#stock = find(:item, object_type: { name: ""})[0]
		
		take [flask], interactive: true
		dh5alpha = produce new_sample "DH5alpha", of: "E coli strains", as: "E coli Glycerol Stocks"
		
		show {
			title "Label Baffled Flask"	
			note "Label the flask '125 mL baffled flask', #{flask.id}, initials, and date"
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
			note "Take DH5alpha glycerol stock, located at M80.X.X.X"
			note "Put glycerol stock in tube rack, loosen cap"
			note "Take lid off flask"
			note "Put tip on pipette"
			note "Leaving glycerol stock in rack, take off cryotube lid, scrape a large chunk from glycerol stock, and replace cryotube lid"
			note "Carefully scrape glycerol into flask of LB by tipping flask and swirling tip into media"
			note "Discard tip"
			note "Return cap on flask"
			note "Return glycerol stock"
		}

		show {
			title "Clean up"
			note "Take pipette, tips back to bench"
		}
		
		show {
			title "Return"
			note "Place flask into the 37 shaker"
		}

	end
end
