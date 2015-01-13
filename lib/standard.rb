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

		params = ({ multiple: false, quantity: 1, take: false, object_type: type }).merge p
		params[:multiple] = true if params[:quantity] > 1

    if params[:object_type]
  		options = find(:item, sample: {name: sample_name}).reject { |i| /eleted/ =~ i.location }
    else
      options = find(:item, sample: {name: sample_name}).reject { |i| /eleted/ =~ i.location }
    end
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

  def move items, new_location
    # takes items (array or single objects) and move location to new_location
    new_location = new_location.to_s
    items = [items] unless items.kind_of?(Array)
    items.each do |i|
      raise "Must be Item or Array of Items to move" unless i.class == Item
      i.location = new_location
      i.save
    end
  end # move

  def delete items
    # invoke mark_as_deleted for each item in items
    items = [items] unless items.kind_of?(Array)
    items.each do |i|
      raise "Must be Item or Array of Items to delete" unless i.class == Item
      i.mark_as_deleted
      i.save
    end
  end # delete

  def task_group_filter task_ids, group
    # filter out task_ids based on group parameter
    # current rule is if group is "technicians", it will return task_ids belong to "cloning", if group is 
    # not "technicians", it will retrun task_ids belong to the group.
    filtered_task_ids = []
    task_ids.each do |tid|
      task = find(:task, id: tid)[0]
      if group == "technicians"
        user_group = "cloning"
      else
        user_group = group
      end
      group_info = Group.find_by_name(user_group)
      if task.user.member? group_info.id
        filtered_task_ids.push tid
      else
        show {
          note "#{task.user.login} does not belong to #{user_group}"
        }
      end
    end
    return filtered_task_ids
  end
end