class Protocol
	
	def arguments
    		{
    			batch: 1,
    		}
	 end
	
	def main
		
		io_hash = input[:io_hash]
		io_hash.has_key?(:measurement) ? (tube = find(:item, id: (io_hash[:tube]))[0]) : (tube = find(:item, object_type: {name: "1.5mL tube"})[0])
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

		io_hash = {measurement: data[:measurement], tube: tube}.merge(io_hash)
		release([tube], interactive: true)
		return { io_hash: io_hash}
	end
end
