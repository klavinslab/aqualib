class Protocol
	def main

		media_type = "50% Glycerol"

		glycerol = find(:item, { object_type: { name: "Glycerol" } } )[0]
		bottle = find(:item, { object_type: { name: "1 L Bottle" } } )[0]

		show {
			title "About this protocol"
			note "This protocol makes #{media_type} for E. coli and yeast media."
		}

		take [glycerol, bottle], interactive: true

		show {
			title "Measure out glycerol"
			check "Find a graduated cylinder."
			check "Using the graduated cylinder, measure 400 mL Glycerol and pour into the 1 L bottle."
			warning "Glycerol is very viscous, be sure to add the correct amount to the bottle."
		}

		show {
			title "Add DI Water"
			note "Using the DI water carboy, DI water up to the 800 mL mark on the bottle."
		}

		media = produce new_sample "50% glycerol", of: "Media", as: "800 mL Liquid"

		media.location = "To be autoclaved area"

		show {
			title "Label"
			note "Label the bottle with 50% glycerol, #{media}, the date, and your initials"
		}

		release [glycerol, media], interactive: true
		
		release [bottle]
	end
end
