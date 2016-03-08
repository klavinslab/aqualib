class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
	def main
		
		io_hash = input[:io_hash]

		show {
			title "While Tubes Are Centrifuging:"
			note "Place an aluminum tube rack on an ice block, and arrange open, empty, chilled 0.6 mL tubes in every other well."
			note "Place ice block, aluminum tube rack, and arranged 0.6 mL tubes into the freezer."
			note "Take an empty, sterile 1.5 mL tube and add 990 uL GYT. Label tube with “1:100 dilution”."
			note "Pour water out of ice bucket, and fill a smaller bucket with remaining ice."
			note "Move P1000 pipette, pipette tips, and tip waste to the dishwashing station. Set the P1000 pipette to 1000 uL."
		}

		show {
			title "Decant Supernatant And Pipette Out Remaining Liquid"
			note "When the spin is finished, take the 225 mL tube out of the centrifuge and immerse in ice."
			note "Take the ice bucket to the dishwashing station and carefully pour the supernatant out of the tube. While the tube is still tilted, carefully pipette out any remaining liquid."
			warning "BE CAREFUL NOT TO DISTURB THE PELLET."
			note "Immerse tube in ice immediately after pipetting out remaining liquid."
			note "Discard the balance tube and return pipette, tips, and tip waste to bench."
		}


		show {
			title "Resuspend in GYT"
			note "Pipette 1.6 mL GYT into remaining 225 mL centrifuge tube."
			note "Vortex until pellet is completely resuspended."
			note "Immerse tube in ice once resuspended."
		}

		res = -1
		while(res < 0)
			data = show {
				title "Prepare And Nanodrop 1:100 Dilution"
				note "Pipette 10 uL of resuspended cells into tube labeled “1:100 dilution”."
				note "Make sure nanodrop is in cell culture mode, initialize if necessary."
				note "Blank the nanodrop with GYT."
				note "Measure OD 600 of 1:100 dilution."
				get "number", var: "measurement", label: "Enter the OD value", default: -1
			}
			res = data[:measurement]
		end

		if(res > 0.1)
			vol = (res * 10 * 2.5 * 10**8 * 100 * 1.6) / (2.5 * 10**10) - 1.6
			title "Add More GYT"
			note "Add #{vol} mL more of GYT to the cells"
		end

		show {
			title "Aliquot"
			note "Take ice block, aluminum tube rack, and arranged 0.6 mL tubes out of the freezer."
			note "Aliquot 40 uL of cells into each 0.6 mL tube until the 225 mL tube is empty."
			note "Vortex the 225 mL tube and change tips periodically, adding more 0.6 mL tubes to the aluminum tube rack if required."
		}

		show {
			title "Move Electrocompetent Aliquots To The -80 Freezer"
			note "Take an empty freezer box, and label it with “DH5alpha”, the date, your initials, and the ID number of the electrocompetent batch."
			note "QUICKLY transfer the aliquoted tubes to the labeled box and move to the -80 freezer."
		}

		show {
			title "Clean Up"
			note "Dispose of empty 225 mL centrifuge tubes."
			note "Pour remaining ice into sink at dishwashing station."
			note "Return ice block and aluminum tube rack."
		}	
		return {io_hash: io_hash}
	end
end
