#
# Standard
#

module Standard

	def choose_sample sample_name

		options = find(:item, sample: {name: sample_name}).reject { |i| i.location == 'deleted' }

		raise "No choices found for #{sample_name}" if options.length == 0

		choices = options.collect { |ps| "#{ps.id}: #{ps.location}" }

		user_input = show {
		  title "Choose #{sample_name} to use"
		  note "There may be several of these items in stock. Choose the oldest one. If there are any that are empty or expired, please discard them and edit the inventory appropriately."
		  select choices, var: "x", label: "Choose #{sample_name}" 
		}

		item = options[choices.index(user_input[:x])]

		take [ item ], interactive: true

		return item

	end


    def choose_object object_name

		options = find(:item, object_type: {name: object_name}).reject { |i| i.location == 'deleted' }

		raise "No choices found for #{object_name}" if options.length == 0

		choices = options.collect { |i| "#{i.id}: #{i.location}" }

		user_input = show {
		  title "Choose #{object_name} to use"
		  note "There may be several of these items in stock. Choose the oldest one. If there are any that are empty or expired, please discard them and edit the inventory appropriately."
		  select choices, var: "x", label: "Choose #{object_name}" 
		}

		item = options[choices.index(user_input[:x])]

		take [ item ], interactive: true

		return item

	end


end