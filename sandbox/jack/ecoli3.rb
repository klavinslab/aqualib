class Protocol
	
	def arguments
		{
			io_hash: {}
		}
	end
	
	
	def main
		
		io_hash = input[:io_hash]
		bottle_1L = find(:item, object_type: { name: "1 L Bottle" } )[0]
		lb_liquid = find(:item, object_type: { name: "800 mL LB liquid (sterile)" } )[6]
		take bottle_1L, interactive: true
		show {
			title "Place LB in heat bath"
			note "Set heat bath to 37"
			note "Once temperature reaches 37, immerse LB in beads"
		}
		lb_liquid.location = "beads"
		io_hash = {new_lb_liquid: lb_liquid}.merge(io_hash)
		release(lb_liquid, interactive: true)
		return { io_hash: io_hash }
	end
end
