class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
	def main
		
		io_hash = input[:io_hash]
		tube = find(:item, object_type: {name: "1.5mL tube"})[0]
		flask2000 = find(:item, id: (io_hash[:dh5alpha_new]))[0]
		take [flask2000, tube], interactive: true
		tube.location = "Bench"

		show {
			title "Make aliquot"
			note "Carefully pipette 100 uL from culture into labeling tube, swirling the flask before pipetting out culture"
		}

		release([flask2000], interactive: true)

		data = show {
			title "Nanodrop"
			note "Make sure nanodrop is in cell culture mode, initialize if necessary"
			note "Blank with LB"
			note "Measure OD 600 of aliquot"
			get "number", var: "measurement", label: "Enter the OD value", default: 0
		}
		if(data[:measurement] <= 0.04) {
			finished = "no"
		} else {
			finished = "yes"
		}
		release([tube], interactive: true)
		return {io_hash: io_hash, done: finished}
	end
end
