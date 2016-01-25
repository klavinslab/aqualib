class Protocol
	
	def arguments
	    {
	    	io_hash: {}
	    }
	end
	
	def main
		io_hash = input[:io_hash]
		data = show {
			title "Select media type"
			select ["LB Liquid", "TB Liquid", "LB Agar"], var: "choice", label: "Choose media", default: "LB Liquid"
		}
		media = data[:choice]
		if(media == "LB Agar")
			amount = 29.6
			ingredient = find(:item,{object_type:{name:"Difco LB Broth, Miller"}})[0]
			produced_media = produce new_object "800 mL LB liquid (unsterile)"
		elsif(media == "LB Liquid Media")
			amount = 20
			ingredient = find(:item,{object_type:{name:"Difco LB Broth, Miller"}})[0]
			produced_media = produce new_object "800 mL LB liquid (unsterile)"
		elsif(media == "TB Liquid Media")
			amount = 20
			ingredient = find(:item,{object_type:{name:"Terrific Broth, modified"}})[0]
			produced_media = produce new_object "800 mL TB liquid (unsterile)"
		else 
			raise ArgumentError, "User input is not valid"
		end
		bottle = find(:item, object_type: { name: "1 L Bottle"})[0]
		take [ingredient, bottle], interactive: true
		produced_media.location = "Bench"
		bottle.mark_as_deleted
		io_hash = {media: produced_media}.merge(io_hash)
		show {
			title "#{media}"
			note "Description: This prepares a bottle of #{media} for growing bacteria"
		}
		
		show {
			title "Get Bottle and Stir Bar"
			note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
		}
		
		show {
			title "Weigh Out #{media}" 
			note "Using the gram scale, large weigh boat, and chemical spatula, weigh out #{amount} grams of #{media} powder and pour into the bottle."
			warning "Before and after using the spatula, clean with ethanol"
		}
		
		show {
			title "Measure Water"
			note "Take the bottle to the DI water carboy and add water up to the 800 mL mark"
		}
		
		show {
			title "Mix solution"
			note "Shake until most of the powder is dissolved."
			note "It is ok if a small amount of powder is not dissolved because the autoclave will dissolve it"
		}
		
		show {
			title "Label Media"
			note "Label the bottle with '#{media}', 'Your initials'"
		}
		release([ingredient, produced_media], interactive: true)
		return {io_hash: io_hash}
	end
end
