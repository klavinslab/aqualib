class Protocol
	def main

		ingredients = find(:item, object_type: { name: "125 mL baffled flask"})
		take ingredients, interactive: true
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
			note "Carefully glycerol scrape into flask of LB by tipping flask and swirling tip into media"
			note "Discard tip"
			note "Return cap on flask"
			note "Return glycerol stock"
		}

		show {
			title "Clean up"
			note "Take pipette, tips back to bench"

		}

		release([ingredients], interactive: true)
	end
end
