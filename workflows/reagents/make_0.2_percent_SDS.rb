
class Protocol
	def main

		media_type = "0.2% SDS"

		sds = find(:item, { object_type: { name: "10% SDS" } })[0]
		bottle = find(:item, { object_type: { name: "250 mL Bottle" } } )[0]

		show {
			title "About this protocol"
			note "This protocol makes #{media_type}."
		}

		take [sds, bottle], interactive: true

		show {
			title "Measure out SDS"
			check "Find a serological pipette."
			check "Using the serological pipette, measure 4 mL 10% SDS and pipette into the 200 mL bottle."
		}

		show {
			title "Add DI Water"
			note "Using the DI water carboy, fill with DI water up to the 200 mL mark on the bottle."
		}

		show {
			title "Label"
			note "Label the bottle with #{media_type}, your initials, and the date."
		}

		media = produce new_sample "0.2% SDS", of: "Media", as: "200 mL Liquid"

		media.location = "To be autoclaved area"

		release [sds, media], interactive: true
		
		release [bottle]
	end
end