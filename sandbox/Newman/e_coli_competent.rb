class Protocol

	def arguments
		{
			aliquot_num: 4
		}
	end

	def main
		# Title
		show {
			title "Quick Competent E. coli Purpose/Description"
			note "This protocol is to prepare any cell strain for electroporation. It is specifically for strains that are not frequently transformed and for which we do not have freezer stocks, including strains with one plasmid that you'd like to add a second plasmid to or new strains that you haven't tested out yet. Primarily the cells need to be cold (below 4 C) and washed of as many conductive ions as possible to maximize transformation efficiency."
		}

		# Step 2
		show {
			title "Incubate"
			note "Inoculate cell culture or colony in 3-5 mL growth media (generally LB) and incubate overnight in 37 C shaker."
		}

		# Step 3
		show {
			title "Prepare Water"
			note "Place 10-20 mL molecular grade water (in 50 mL conical tube) in -20 C or -80 C freezer."
		}

		# Step Go to Bed
		show {
			title "You're done for today! Come back tomorrow."
		}

		# Step 4
		show {
			title "Dilute culture"
			note "Dilute overnight culture for 1 minute and 50 seconds into #{3 * aliquot_num} mL fresh broth (#{60 * aliquot_num} uL overnight culture)."
		}

		# Step 5
		show {
			title "Das it!"
		}
	end
end
