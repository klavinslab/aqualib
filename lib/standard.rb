#
# Standard
#

require 'active_support/inflector'

module Standard

  # TODO: choose_sample and choose_object share a lot of code. They should be refactored to reuse the code

	def choose_sample sample_name, p={}

		# Directs the user to take an item or items associated with the sample defined by sample_name.
		# Options:
		#   multiple : false          --> take one or take multiple items. if multiple, then a list of items is returned
    #   quantity : n              --> the number of items to take. sets multiple to true if greater than 1
    #   take : false              --> does an interactive take if true

    if block_given?
      user_shows = ShowBlock.new.run(&Proc.new) 
    else
      user_shows = []
    end

		params = ({ multiple: false, quantity: 1, take: false }).merge p
		params[:multiple] = true if params[:quantity] > 1

		options = find(:item, sample: {name: sample_name}).reject { |i| /eleted/ =~ i.location }
		raise "No choices found for #{sample_name}" if options.length == 0

		choices = options.collect { |ps| "#{ps.id}: #{ps.location}" }

		quantity = -1

		while quantity != params[:quantity]

			user_input = show {
				if params[:quantity] == 1
				  title "Choose a #{sample_name}"
				else
				  title "Choose #{params[:quantity]} #{sample_name.pluralize}"
				end
			  if quantity >= 0 
			  	note "Try again. You chose the wrong number of items"
			  end
			  raw user_shows
			  select choices, var: "x", label: "Choose #{sample_name}", multiple: params[:multiple]
			}

			if ! user_input[:x]
				user_input[:x] = []
			end

			if params[:quantity] != 1
				quantity = user_input[:x].length
			else
				quantity = 1
			end

		end

		if params[:quantity] == 1
			user_input[:x] = [ user_input[:x] ]
		end

		items = user_input[:x].collect { |y| options[choices.index(y)] }

		if params[:take]
			take items, interactive: true
		end

		if params[:multiple]
			return items
		else
			return items[0]
		end

	end

  def choose_object object_name, p={}

		# Directs the user to take an item or items associated with the object defined by object_name
		# Options:
		#   multiple : false          --> take one or take multiple items. if multiple, then a list of items is returned
    #   quantity : n              --> the number of items to take. sets multiple to true if greater than 1
    #   take : false              --> does an interactive take if true

    if block_given?
      user_shows = ShowBlock.new.run(&Proc.new) 
    else
      user_shows = []
    end

		params = ({ multiple: false, quantity: 1, take: false }).merge p
		params[:multiple] = true if params[:quantity] > 1

		options = find(:item, object_type: {name: object_name}).reject { |i| /eleted/ =~ i.location }
		raise "No choices found for #{object_name}" if options.length == 0

		choices = options.collect { |i| "#{i.id}: #{i.location}" }

		quantity = -1

		while quantity != params[:quantity]

			user_input = show {
				if params[:quantity] == 1
				  title "Choose #{object_name} to use"
				else
					title "Choose #{params[:quantity]} #{object_name.pluralize}"
				end
  		  if quantity >= 0 
			  	note "Try again. You chose the wrong number of items"
			  end
	      raw user_shows
			  select choices, var: "x", label: "Choose #{object_name}" , multiple: params[:multiple]
			}

			if ! user_input[:x]
				user_input[:x] = []
			end

			if params[:quantity] != 1
				quantity = user_input[:x].length
			else
				quantity = 1
			end

		end

  	if params[:quantity] == 1
			user_input[:x] = [ user_input[:x] ]
		end

		items = user_input[:x].collect { |y| options[choices.index(y)] }

		if params[:take]
			take items, interactive: true
		end

		if params[:multiple]
			return items
		else
			return items[0]
		end

	end

  def debug_mode arg
	  # only takes true or false as argument
	  	if arg == true
	  		def self.included base
		  		base.instance_eval do
			  		def debug
			  			true
			  		end
		  	  end
	  	  end
	  	  return 1
	  	elsif arg == false
	  		def debug
	  			false
	  		end
	  		return 0
	  	end
  end

end