class Protocol
	def main

		media_type = "50% PEG"

		peg_3350= find(:item, { object_type: { name: "PEG 3350" } } )[0]
		bottle = find(:item, { object_type: { name: "250 mL Bottle" } } )[0]
		medium_magnetic_stir_bar = find(:item, { object_type: { name: "Medium Magnetic Stir Bar"} } )[0]
		stir_plate = find(:item, { object_type: { name: "Hot/Stir Plate"} } )[0]
		bottle_top_filter = find(:item, { object_type: { name: "1 L Bottle Top Filter"} } )[0]

		show {
			title "About this protocol"
			note "This protocol makes #{media_type} for yeast transformations."
		}

		take [peg_3350, bottle, medium_magnetic_stir_bar], interactive: true 

		show {
			title "Weigh out PEG 3350"
			check "Add stir bar to bottle."
			check "Weigh out 100g of PEG 3350 and add to each bottle."
		}

		show {
			title "Add DI Water"
			check "Take the bottle to the DI water carboy and add water up to the 200 mL mark."
			check "Label bottle with 50% PEG, the date and your initials."
		}

		show {
			title "Stir Solution"
			check "Stir solution until all contents are well mixed."
			warning "May require heating at 80C for an extended period of time."
		}

		take [bottle_top_filter, bottle], interactive: true

		show {
			title "Filter sterilize 50$ PEG"
			check "Screw bottle top filter onto empty 250 mL bottle and connect to vacuum."
			check "Turn on vacuum and slowly add the unsterilized 50% PEG."
			check "Once all solution has been sterilized, turn off vacuum, remove and throw away bottle top filter."
		}

		
		media = produce new_sample "50% PEG", of: "Media", as: "200 mL Liquid"

		media.location = "B1.565"
		
		show {
			title "Label"
			note "Label bottle with 50% PEG, filter sterilized, #{media}, the date, and your initials."
		}

		release [media, peg_3350, bottle], interactive: true

		release [bottle]
	end
end