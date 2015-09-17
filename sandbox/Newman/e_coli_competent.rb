class Protocol

	def arguments
		{
			aliquot_num: 4
		}
	end

	def main

		aliquot_num = input[:aliquot_num]

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
			timer initial: { hours: 0, minutes: 1, seconds: 50}
		}

		# Step 5
		show {
			title "Incubate and check OD600"
			note "Incubate at 37 C for 1-3 hours. Check OD600 on Nanodrop after 1 hour. The target OD600 is 0.4-0.6."
			note "Note: Multiply the absorbance value at 600 nm measured by the Nanodrop by a factor of 10 to get OD600."
			timer initial: { hours: 1, minutes: 0, seconds: 0}
		}

		# Step 6
		show {
			title "Add Water"
			note "Place water from freezer in ice bath, and add 5-10 mL room temperature molecular grade water and shake to cool."
		}

		2.times {
			# Step 7
			show {
				title "Run in Centrifuge"
				note "Pellet cell culture in 1.5 mL tubes (1 mL culture per tube) by running in refrigerated centrifuge (4 C) for 1 minute at 6000 xg."
				timer initial: { hours: 0, minutes: 1, seconds: 0}
			}

			# Step 8
			show {
				title "Resuspend Cells"
				note "Remove supernatant. Add 1 mL ice cold water and resuspend cells."
			}
		}

		# Step 9
		show {
			title "Resuspend Cells"
			note "Resuspend cells in 40 uL ice cold water."
		}

		# Step 10
		show {
			title "Follow electroporation protocol."
		}
	end
end
