#
# Standard
#

module Standard

	def choose_sample sample_name, p={}

    if block_given?
      user_shows = ShowBlock.new.run(&Proc.new) 
    else
      user_shows = []
    end

		params = ({ multiple: false, quantity: 1 }).merge p
		params[:multiple] = true if params[:quantity] > 1

		options = find(:item, sample: {name: sample_name}).reject { |i| /eleted/ =~ i.location }

		raise "No choices found for #{sample_name}" if options.length == 0

		choices = options.collect { |ps| "#{ps.id}: #{ps.location}" }

		quantity = -1
		while quantity != params[:quantity]

			user_input = show {
			  title "Choose #{params[:quantity]} #{sample_name} to use"
			  if quantity >= 0 
			  	note "Try again. You chose the wrong amount"
			  end
			  raw user_shows
			  select choices, var: "x", label: "Choose #{sample_name}", multiple: params[:multiple]
			}

			quantity = user_input[:x].length

		end

		items = user_input[:x].collect { |y| options[choices.index(y)] }

		take items, interactive: true

		return item

	end


    def choose_object object_name

		options = find(:item, object_type: {name: object_name}).reject { |i| /eleted/ =~ i.location }

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