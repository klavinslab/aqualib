class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end	
	
	def main

		io_hash = input[:io_hash]
		flask = find(:item, object_type: { name: "125 mL baffled flask"})[0]
		lb_liquid = find(:item, { sample: { name: "LB"}, object_type: { name: "800 mL Liquid" }})[0]
		#lb_liquid = find(:item, object_type: { name: "800 mL LB liquid (sterile)"})[0]
		stock = find(:item, { sample: { name: "DH5alpha"}, object_type: { name: "Agar Plate" }})[0]
		
		take [flask, lb_liquid], interactive: true
		dh5alpha = produce new_sample "DH5alpha", of: "E coli strain", as: "Overnight Suspension"
		dh5alpha.location = "37 degree shaker"
		io_hash = {dh5alpha: dh5alpha.id}.merge(io_hash)
		
		show {
			title "Label Baffled Flask"	
			note "Label the flask 'DH5alpha', #{dh5alpha.id}, initials, and date"
		}
		
		show {
			title "Add LB Liquid"
			note "Using the serological pipette, add 25 mL LB liquid to the baffled flask"
		}
		
		take [stock], interactive: true

		show {
			title "Inoculate From Agar Plate"
			note "Select and isolate colony on plate, circle and label with today's date"
			note "Using a pipette tip, carefully scrape the selected colony"
			note "Maintaining a good sterile technique, carefully tilt the flask of LB and swirl pipette tips with cells into the media"
		}
		
		release([flask])
		release([stock, dh5alpha, lb_liquid], interactive: true)
		
		return { io_hash: io_hash }
		
		

	end
end
