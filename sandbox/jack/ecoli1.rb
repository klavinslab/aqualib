class Protocol
	
	def arguments
    		{
    			batch: 1,
    			io_hash: {}
    		}
	 end
	
	def main
		
		batch = input[:batch]
		io_hash = input[:io_hash]
		bottle_1L = find(:item, object_type: { name: "1 L Bottle"})[0]
		bottle_500mL = find(:item, object_type: { name: "500 mL Bottle"})[0]
		broth = find(:item, object_type: { name: "Difco LB Broth, Miller"})[0]
		glycerol_fifty = find(:item, object_type: { name: "50 percent Glycerol (sterile)"})[0]

		take [bottle_1L, bottle_1L, bottle_500mL, broth, glycerol_fifty], interactive: true

		lb_liquid = produce new_object "800 mL LB liquid (unsterile)"
		glycerol = produce new_object "500 mL 10 Percent Glycerol (unsterile)"
		water = produce new_object "1000 mL DI Water (unsterile)"
		lb_liquid_sterile = produce new_object "800 mL LB liquid (sterile)"
		glycerol_sterile = produce new_object "500 mL 10 Percent Glycerol (sterile)"
		water_sterile = produce new_object "1000 mL DI Water (sterile)"
		lb_liquid.mark_as_deleted
		glycerol.mark_as_deleted
		water.mark_as_deleted
		
		io_hash = {lb_liquid: lb_liquid_sterile, water: water_sterile, glycerol: glycerol_sterile}.merge(io_hash)

		show {
			title "Prepare Bottles"
			note "Remove autoclave tape from each bottle"
			note "Add a piece of labeling tape to each bottle"
		}

		show {
			title "Prepare 800 mL LB liquid"
			note "Label one 1 L bottle with '800 mL LB Liquid', #{lb_liquid_sterile.id}, initials, and date"
			note "Wipe spatula with ethanol and kimwipe"
			note "Measure out 20 g LB Broth, Miller on scale and add to labeled bottle"
			note "Wipe spatula with ethanol and kimwipe"
		}

		show {
			title "Prepare 500 mL 10 Percent Glycerol (unsterile)"
			note "Label 500 mL bottle '500 mL 10% Glycerol', #{glycerol_sterile.id}, initials, and date"
			note "Using a serological pipette, add 100 mL 50% glycerol to 500 mL bottle"
		}

		show {
			title "Prepare 1 L DI Water (unsterile)"
			note "Label remaining 1 L bottle '1 L DI Water (unsterile)', #{water_sterile.id}, initials, and date"
		}

		show {
			title "Add DI water"
			note "Add DI water to '800 mL LB Liquid' up to 800 mL mark"
			note "Add DI water to '500 mL 10% Glycerol' up to 500 mL mark"
			note "Add DI water to '1 L DI Water' up to 1 L mark"
		}

		show {
			title "Autoclave"
			note "Add autoclave tape to '800 mL LB Liquid', '500 mL 10% Glycerol', and '1 L DI Water'"
			note "Check water levels in autoclave"
			note "Load '800 mL LB Liquid', '500 mL 10% Glycerol', and '1 L DI Water' into autoclave"
			note "Set autoclave to 121 C for 15 minutes, and start"
		}

		release([glycerol_sterile, water_sterile, lb_liquid_sterile, bottle_1L, bottle_1L, bottle_500mL, broth, glycerol_fifty], interactive: true)
		return { io_hash: io_hash}
	end
end
