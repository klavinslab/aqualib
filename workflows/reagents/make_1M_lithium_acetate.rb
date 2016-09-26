class Protocol 
	def main

		media_type = "1M Lithium Acetate"

		lithium_acetate = find(:item, { object_type: { name: "Lithium Acetate" } } )[0]
		bottle = find(:item, { object_type: { name: "250 mL Bottle" } } )[0]
		bottle_top_filter = find(:item, { object_type: { name: "1 L Bottle Top Filter"} } )[0]

		show {
			title "About this protocol"
			note "This protocol makes #{media_type} for yeast transformations."
		}

		take [lithium_acetate, bottle], interactive: true 

		show {
			title "Weigh out Lithium Acetate"
			check "Weigh out 13.2g Lithium Acetate and add to bottle. "
		}

		show {
			title "Add DI Water"
			check "Take the bottle to the DI water carboy and add water up to the 200 mL mark."
			check "Shake until all contents are well mixed."
		}

		take [bottle_top_filter, bottle], interactive: true

		show {
			title "Filter sterilize Lithium Acetate"
			check "Screw bottle top filter onto empty 250 mL bottle and connect to vacuum."
			check "Turn on vacuum and slowly add the unsterilized 1 M Lithium Acetate."
			check "Once all solution has been sterilized, turn off vacuum, remove and throw away bottle top filter."
		}

		
		media = produce new_sample "1 M Lithium Acetate", of: "Media", as: "200 mL Liquid"

		media.location = "B1.565"
		
		show {
			title "Label"
			note "Label bottle with Lithium Acetate, filter sterilized, #{media}, the date, and your initials."
		}

		release [media, lithium_acetate, bottle], interactive: true

		release [bottle]
	end
end