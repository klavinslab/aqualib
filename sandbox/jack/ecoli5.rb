class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
	def main
		
		io_hash = input[:io_hash]
		flask2000 = find(:item, id: (io_hash[:dh5alpha_new]))[0]
		take [flask2000], interactive: true
		
		show {
			title "Take 1.5 mL tube"
			note "Get a 1.5 mL tube and bring it to the workbench"
		}

		show {
			title "Make aliquot"
			note "Carefully pipette 100 uL from culture into labeling tube, swirling the flask before pipetting out culture"
		}

		release([flask2000], interactive: true)

		res = -1
		while(res < 0)
			data = show {
				title "Nanodrop"
				note "Make sure nanodrop is in cell culture mode, initialize if necessary"
				note "Blank with LB"
				note "Measure OD 600 of aliquot"
				get "number", var: "measurement", label: "Enter the OD value", default: -1
			}
			res = data[:measurement]
		end
		if(res <= 0.04) 
			finished = "no"
		else 
			finished = "yes"
		end
		
		show {
			title "Return tube"
			show "Return the 1.5 mL tube to the dishwashing station"
		}
		return {io_hash: io_hash, done: finished}
	end
end
