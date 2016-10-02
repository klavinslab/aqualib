class Protocol
	def main

		media_type = "50X TAE"

		tris= find(:item, { object_type: { name: "Tris-base" } } )[0]
		bottle = find(:item, { object_type: { name: "800 mL Bottle" } } )[0]
		edta = find(:item, { object_type: { name: "EDTA Disodium Salt"} } )[0]
		acetic_acid = find(:item, { object_type: { name: "Acetic Acid, Glacial"}})

		show {
			title "About this protocol"
			note "This protocol makes #{media_type} for gel electrophoresis."
		}

		take [tris, bottle, edta, acetic_acid], interactive: true 

		show {
			title "Weigh out Tris-base"
			check "Weigh out 242g of Tris-base and add to each bottle."
		}

		show {
			title "Weigh out EDTA Disodium Salt"
			check "Weigh out 14.62g EDTA Disodium Salt and add to each bottle."
		}

		show {
			title "Measure out Acetic Acid"
			check "Find a graduated cylinder."
			check "Using the graduated cylinder, measure out 57.7mL of Acetic Acid, Glacial and add to each bottle."
		}

		show {
			title "Add DI Water"
			check "Take the bottle to the DI water carboy and add water up to the 1L mark."
			check "Label bottle with 50X TAE, #{media}, the date and your initials."
		}

		show {
			title "Mix Solution"
			check "Shake the solution until all contents are well mixed."
		}
		
		media = produce new_sample "50X TAE", of: "Media", as: "1 L Liquid"

		media.location = "A5.505"

		release [media, tris, edta, acetic_acid, bottle], interactive: true

	end
end