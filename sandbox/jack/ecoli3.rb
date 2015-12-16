class Protocol
	def main
		ingredients = find(:item, object_type: { name: "800 mL LB liquid"})
		show {
			title "Place LB in heat bath"
			show "Set heat bath to 37"
			show "Once temperature reaches 37, immerse LB in beads"
		}
	end
end
