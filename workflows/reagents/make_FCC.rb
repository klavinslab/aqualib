class Protocol
	def main

		media_type = "FCC"
        
        glycerol = find(:item, { object_type: {name: "Glycerol"}}) [0]
        water = find( :item, {object_type: {name: "Molecular Biology Grade Water"}})[0]
		dmso = find(:item, { object_type: { name: "DMSO" } } )[0]
		bottle = find(:item, { object_type: { name: "250 mL Bottle" } } )[0]

		show {
			title "About this protocol"
			note "This protocol makes #{media_type} for yeast transformations."
		}

		take [glycerol, water, dmso, bottle], interactive: true

		show {
			title "Measure out DMSO"
			check "Find a 25 mL serological pipette tip."
			check "Using the serological pipette measure out 20 mL of DMSO and add to the bottle."
		}

		show {
			title "Measure out glycerol"
			check "Find a graduated cylinder."
			check "Using the graduated cylinder, measure 20 mL Glycerol and pour into the bottle."
			warning "Glycerol is very viscous, be sure to add the correct amount to the bottle."
		}

		show {
			title "Add Molecular Grade Water"
			check "Find a graduated cyliner."
			check "Using the graduated cylinder, measure out 160 mL Molecular Grade Water and add to bottle."
		}

		show {
			title "Mix solution"
			note "Shake until all contents are well mixed."
		}

		show {
			title "Label"
			note "Label the bottle with #{media_type} your initials, and the date."
		}

		media = produce new_sample "FCC", of: "Media", as: "200 mL Liquid"

		media.location = "To be autoclaved area"

		release [glycerol, water, dmso, media], interactive: true
		
		release [bottle]
	end
end

