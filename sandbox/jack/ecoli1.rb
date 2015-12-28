class Protocol
	def main

		ingredients = find(:item, object_type: { name: "1 L Bottle"}) + find(:item, object_type: { name: "1 L Bottle"}) +
				find(:item, object_type: { name: "500 mL Bottle"}) + find(:item, object_type: { name: "Difco LB Broth, Miller"}) +
				find(:item, object_type: { name: "50 percent Glycerol (sterile)" } )[0]

		take ingredients, interactive: true

		lb_liquid = produce new_object "800 mL LB liquid (unsterile)"
		#glycerol = produce new_object "500 mL 10 Percent Glycerol (unsterile)"
		#water = produce new_object "1000 mL DI Water (unsterile)"
		#lb_liquid_sterile = produce new_object "800 mL LB liquid (sterile)"
		#lb_liquid.mark_as_deleted

		show {
			title "Prepare Bottles"
			note "Remove autoclave tape from each bottle"
			note "Add a piece of labeling tape to each bottle"
		}

		show {
			title "Prepare 800 mL LB liquid"
			note "Label one 1 L bottle with '800 mL LB Liquid', #{item number}, initials, and date"
			note "Wipe spatula with ethanol and kimwipe"
			note "Measure out 20 g LB Broth, Miller on scale and add to labeled bottle"
			note "Wipe spatula with ethanol and kimwipe"
		}

		show {
			title "Prepare 500 mL 10 Percent Glycerol (unsterile)"
			note "Label 500 mL bottle “500 mL 10% Glycerol” with item number from silent produce, your initials, and the date"
			note "Using a serological pipette, add 100 mL 50% glycerol to 500 mL bottle"
		}

		show {
			title "Prepare 1 L DI Water (unsterile)"
			note "Label remaining 1 L bottle “1 L DI Water (sterile)” with item number from silent produce, your initials, and the date"
		}

		show {
			title "Add DI water"
			note "Add DI water to “800 mL LB Liquid” up to 800 mL mark"
			note "Add DI water to “500 mL 10% Glycerol” up to 500 mL mark"
			note "Add DI water to “1 L DI Water (sterile)”  up to 1 L mark"
		}

		show {
			title "Autoclave"
			note "Add autoclave tape to  800 mL LB Liquid, 500 mL 10% Glycerol, and 1 L DI Water (sterile)"
			note "Check water levels in autoclave"
			note "Load 800 mL LB Liquid, 500 mL 10% Glycerol, and 1 L DI Water (sterile) into autoclave"
			note "Set autoclave to 121 C for 15 minutes, and start"
		}

		release([lb_liquid, glycerol, water, lb_liquid_sterile, ingredients], interactive: true);
	end
end
