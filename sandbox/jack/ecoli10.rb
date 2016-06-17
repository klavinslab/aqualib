class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
	
	def fill_array rows, cols, num, val
	        num = 0 if num < 0
	        array = Array.new(rows) { Array.new(cols) { -1 } }
	        (0...num).each { |i|
	         	row = (i / cols).floor
	          	col = i % cols
	          	array[row][col] = val
	        }
	        array
	end # fill_array
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
			show {
				title "Add More GYT"
				note "Add #{vol} mL more of GYT to the cells"
			}
		end
		res = -1
		while(res < 0)
			data = show {
				title "Aliquot"
				note "Take ice block, aluminum tube rack, and arranged 0.6 mL tubes out of the freezer."
				note "Aliquot 40 uL of cells into each 0.6 mL tube until the 225 mL tube is empty."
				note "Vortex the 225 mL tube and change tips periodically, adding more 0.6 mL tubes to the aluminum tube rack if required."
				get "number", var: "amount", label: "Enter how many aliquots made", default: -1
			} 
			res = data[:amount]
		end
		
		aliquot_batch = produce new_collection "E. coli Comp Cell Batch", 10, 10
		batch_matrix = fill_array 10, 10, res, 7
		aliquot_batch.matrix = batch_matrix
		aliquot_batch.location = "-80 freezer"
		Item.find(aliquot_batch.id).associate "tested", "No", upload=nil
		aliquot_batch.save
		release([aliquot_batch])
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
		
		tp = TaskPrototype.where("name = 'Ecoli Transformation'")[0]
		t = Task.new(name: "Ecoli_Transformation_#{aliquot_batch.id}", 
                specification: { "plasmid_item_ids Plasmid Stock|1 ng/µL Plasmid Stock|Gibson Reaction Result" => find(:item, { sample: { name: "SSJ128" } } )[0].id }.to_json, 
                task_prototype_id: tp.id, 
                status: "waiting", 
                user_id: Job.find(jid).user_id,
                budget_id: 1)
		t.save
		t.notify "Automatically created from Make E Comp Cells.", job_id: jid
		return {io_hash: io_hash}
	end
end
