#
# Standard
#

require 'active_support/inflector'
require 'time'

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

		params = ({ multiple: false, quantity: 1, take: false, object_type: false }).merge p
		params[:multiple] = true if params[:quantity] > 1

    if params[:object_type]
  		options = find(:item, {sample: {name: sample_name}, object_type: {name: params[:object_type]} }).reject { |i| /eleted/ =~ i.location }
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
			  select choices, var: "x", label: "Choose #{sample_name}", multiple: params[:multiple], default: 0
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
			  	note "Try again. You chose the wrong number of items. Use SHIFT to choose multiple items."
			  end
	      raw user_shows
			  select choices, var: "x", label: "Choose #{params[:quantity]} #{object_name}" , multiple: params[:multiple]
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
      i.reload
    end
    release items
  end # move

  def delete items
    # invoke mark_as_deleted for each item in items
    items = [items] unless items.kind_of?(Array)
    items.each do |i|
      raise "Must be Item or Array of Items to delete" unless i.class == Item
      i.mark_as_deleted
      i.save
    end
    release items
  end # delete

  # return the initials of first name and last name
  def name_initials str
    full_name = str.split
    begin
      cap_initials = full_name[0][0].upcase + full_name[1][0].upcase
    rescue
      cap_initials = ""
    end
    return cap_initials
  end

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
      # else
      #   show {
      #     note "#{task.user.login} does not belong to #{user_group}"
      #   }
      end
    end
    return filtered_task_ids
  end

  # a method for finding collections that contains certain sample ids and belongs to a certain object_type that has been created beyond time_frame ago.
  def collection_type_contain id, object_type, time_frame
    matched_collections = []
    find_collections = Collection.containing Sample.find(id)
    if find_collections[0]
      (find_collections).each do |c|
        duration = ((Time.now - c.created_at) / 3600).round
        if c.object_type.name == object_type && duration > time_frame
          matched_collections.push c
        end
      end
    end
    return matched_collections
  end

  # a method for finding collections that contains certain sample ids and belongs to a certain object_type that has datum field entered num_colony. Originally designed for finding Divided Yeast Plate.
  def collection_type_contain_has_colony id, object_type
    matched_collections = []
    find_collections = Collection.containing Sample.find(id)
    if find_collections[0]
      (find_collections).each do |c|
        if c.datum && c.location != "deleted"
          if (c.datum[:num_colony] || 0) > 0
            matched_collections.push c
          end
        end
      end
    end
    return matched_collections
  end

  # fills an array for a collection matrix with a certain number of a certain value (used mostly for batching)
  def fill_array rows, cols, num, val
    num = 0 if num < 0
    array = Array.new(rows) { Array.new(cols) { -1 } }
    (0...num).each { |i|
      row = (i / cols).floor
      col = i % cols
      array[row][col] = val
    }
    array
  end # fill_array

  # sorts a list of items by hotel, box, and slot
  def sort_by_location items
    location_prefix = items[0].location.split(".")[0]
    location_arrays = items.map { |item| item.location[4..-1].split(".") }
    sorted_locations = location_arrays.sort { |row1, row2| 
                                              comp = row1[0].to_i <=> row2[0].to_i
                                              comp = comp.zero? ? row1[1].to_i <=> row2[1].to_i : comp
                                              comp.zero? ? row1[2].to_i <=> row2[2].to_i : comp }
    location_strings = sorted_locations.map { |row| "#{location_prefix}.#{row[0]}.#{row[1]}.#{row[2]}" }
    items.sort_by! { |item| location_strings.index(item.location) }
  end # sort_by_location

  def determine_enough_volumes_each_item items, volumes, opts={}
    return [[],[],[]] if items.empty? || volumes.empty?
    options = { check_contam: false }.merge opts

    total_vols_per_item = total_volumes_by_item items, volumes
    extra_vol = options[:check_contam] ? 0 : 5
    verify_data = show {
      title "Verify enough volume of each #{items[0].object_type.name} exists#{options[:check_contam] ? ", or note if contamination is present" : ""}"
      total_vols_per_item.each { |id, v| 
        choices = options[:check_contam] ? ["Yes", "No", "Contamination is present"] : ["Yes", "No"]
        select choices, var: "#{id}", label: "Is there at least #{(v + extra_vol).round(1)} µL of #{id}?", default: 0 
      }
    }

    bools = items.map { |i| i.nil? ? true : verify_data[:"#{i.id}".to_sym] == "Yes" }
    if options[:check_contam]
      [items.select.with_index { |i, idx| bools[idx] },
      items.select.with_index { |i| i.nil? ? false : verify_data[:"#{i.id}".to_sym] == "No" },
      items.select { |i| i.nil? ? false : verify_data[:"#{i.id}".to_sym] == "Contamination is present" },
      bools]
    else
      [items.select.with_index { |i, idx| bools[idx] },
      items.select.with_index { |i, idx| !bools[idx] },
      bools]
    end
  end
  
  def total_volumes_by_item items, volumes
    vol_hash = {}
    items.compact.each_with_index { |i, idx|
      if vol_hash[i.id].nil?
        vol_hash[i.id] = volumes.compact[idx]
      else
        vol_hash[i.id] += volumes.compact[idx]
      end
    }
    vol_hash
  end
  
  def hash_by_sample items
    item_hash = {}
    items.each { |i|
      if item_hash[i.sample.id].nil?
        item_hash[i.sample.id] = [i]
      else
        item_hash[i.sample.id].push(i)
      end
    }
    item_hash
  end

  def make_purchase origin_task, description, mat, lab
    tp = TaskPrototype.find_by_name("Direct Purchase")
    if tp
      task = tp.tasks.create({
        user_id: origin_task.user_id, 
        name: "#{DateTime.now.to_i} - #{description} from #{origin_task.name}",
        status: "purchased",
        budget_id: origin_task.budget_id,
        specification: {
            description: description,
            materials: mat,
            labor: lab
         }.to_json
      })
      task.save
      if task.errors.empty?
        set_task_status(task,"purchased")
        show {
          note task.name
        }
      else
        error "Errors", task.errors.full_messages.join(', ')
      end
      task
    end
  end
end