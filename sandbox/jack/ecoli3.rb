class Protocol
	
	def arguments
		{
			io_hash: {}
		}
	end
	
	
	def main
		
		io_hash = input[:io_hash]
		lb_liquid = find(:item, id: {(io_hash[:lb_liquid])[:id])
		show {
			note "#{(io_hash[:lb_liquid])[:id]}"
			note "#{lb_liquid}"
		}
		#take [lb_liquid], interactive: true
		show {
			title "Place LB in heat bath"
			note "Set heat bath to 37"
			note "Once temperature reaches 37, immerse LB in beads"
		}
		io_hash = {new_lb_liquid: lb_liquid}.merge(io_hash)
		release([lb_liquid], interactive: true)
		return { io_hash: io_hash }
	end
end
