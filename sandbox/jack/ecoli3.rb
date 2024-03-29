class Protocol
	
	def arguments
		{
			io_hash: {}
		}
	end
	
	
	def main
		
		io_hash = input[:io_hash]
		
		lb_liquid = find(:item, id: (io_hash[:lb_liquid]))[0]
		take [lb_liquid], interactive: true
		show {
			title "Place LB in heat bath"
			note "Set heat bath to 37"
			note "Once temperature reaches 37, immerse LB in beads"
		}
		release([lb_liquid])
		return { io_hash: io_hash }
	end
end
