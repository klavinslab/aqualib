needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  # a function that returns a table of task information
  def task_info_table task_ids

    if task_ids.empty?
      return [[]]
    end

    task_ids.compact!

    if task_ids.length == 0
      return []
    end

    tab = [[ "Task ids", "Task type", "Task name", "Task owner", "Task size"]]

    task_ids.each do |tid|
      task = find(:task, id: tid)[0]
      tab.push [ tid, task.task_prototype.name, task.name, task.user.name, task_size(tid) ]
    end

    return tab

  end

  # a function that returns sample stock ids that has seq_verified marked "correct", if nothing marked, return the 1st one in the array of sample stocks
  # currently works for Fragment and Sample

  def choose_stock sample

    stocks = sample.in(sample.sample_type.name + " Stock")
    if stocks.length > 1
      stocks.each do |stock|
        if stock.datum[:seq_verified] == "correct"
          return stock.id
        end
      end
      return stocks[0].id
    elsif stocks.length == 1
      return stocks[0].id
    else
      return nil
    end

  end

  # choose first x task_ids based on the actual reaction sizes, provide an input select interface to the user.
  def task_choose_limit task_ids, task_prototype_name
    task_ids = [task_ids] unless task_ids.is_a? Array
    if task_ids.empty?
      return []
    end
    sizes = []
    task_ids.each do |id|
      sizes.push(task_size(id) + (sizes[-1] || 0))
    end
    if sizes.empty?
      return []
    end
    limit_input = show {
      title "How many #{task_prototype_name} to run?"
      note "There is a total of #{sizes[-1]} #{task_prototype_name} in the queue. How many do you want to run?"
      select sizes, var: "limit", label: "Enter the number of #{task_prototype_name} you want to run", default: sizes[-1]
    }
    limit_input[:limit] ||= sizes[-1]
    limit_num = limit_input[:limit].to_i
    limit_idx = sizes.index(limit_num)
    return task_ids.take(limit_idx + 1)
  end

  # return the size of a task
  def task_size id
    task = find(:task, id: id)[0]
    task_prototype_name = task.task_prototype.name
    size = 0
    case task_prototype_name
    when "Gibson Assembly"
      size = 1
    when "Fragment Construction", "Mutagenized Fragment Construction"
      size = task.simple_spec[:fragments].length
    when "Sequencing", "Primer Order"
      size = task.simple_spec[:primer_ids].length
    when "Plasmid Verification", "Yeast Strain QC"
      size = task.simple_spec[:num_colonies].inject { |sum, i| sum + i }
    when "Cytometer Reading", "Glycerol Stock", "Discard Item", "Streak Plate"
      size = task.simple_spec[:item_ids].length
    when "Yeast Transformation"
      size = task.simple_spec[:yeast_transformed_strain_ids].length
    when "Sequencing Verification"
      size = task.simple_spec[:plasmid_stock_ids].length
    when "Yeast Mating"
      size = task.simple_spec[:yeast_mating_strain_ids].length
    when "Yeast Competent Cell"
      size = task.simple_spec[:yeast_strain_ids].length
    when "Plasmid Extraction"
      size = task.simple_spec[:glycerol_stock_ids].length
    end
    return size
  end

  def inventory_type_check inventory_types, item_or_sample, id
    if inventory_types == ["Sample"] || inventory_types == ["Item"]
      return true
    elsif item_or_sample == :item
      object_type = find(:item, id: id)[0].object_type.name
      return inventory_types.include? object_type
    elsif item_or_sample == :sample
      sample_type = find(:sample, id: id)[0].sample_type.name
      return inventory_types.include? sample_type
    end
  end

  # returns errors of inventory_check and possible needs for submitting new tasks
  def inventory_check ids, p={}
    params = ({ sample_type: "", inventory_types: "" }).merge p
    ids = [ids] if ids.is_a? Numeric
    ids_to_make = [] # put the list of sample ids that need inventory_type to be made
    sample_type = params[:sample_type]
    inventory_types = params[:inventory_types]
    inventory_types = [inventory_types] if inventory_types.is_a? String
    errors = []
    ids.each do |id|
      sample = find(:sample, id: id)[0]
      sample_name = "#{sample_type} #{sample.name}"
      warning = []
      inventory_types.each do |inventory_type|
        if sample.in(inventory_type).empty?
          warning.push "#{sample_name} does not have a #{inventory_type}."
        end
      end
      if warning.length == inventory_types.length
        errors.push "#{sample_name} requires a #{inventory_types.join(" or ")}."
        ids_to_make.push id
      end
    end
    return {
      errors: errors,
      ids_to_make: ids_to_make
    }
  end

  def sample_check ids, p={}
    params = ({ sample_type: "", assert_property: [], assert_logic: "and" }).merge p
    ids = [ids] if ids.is_a? Numeric
    sample_type = params[:sample_type]
    assert_properties = params[:assert_property]
    assert_properties = [assert_properties] unless assert_properties.is_a? Array
    if sample_type.empty? || assert_properties.empty?
      return nil
    end
    errors = []
    ids_to_make = [] # ids that require inventory to be made through other tasks
    ids.each do |id|
      sample = find(:sample, id: id)[0]
      sample_name = "#{sample_type} #{sample.name}"
      properties = sample.properties.deep_dup
      assert_properties.each do |field|
        warnings = [] # to store temporary errors
        if properties[field]
          property = properties[field]
          case field
          when "Forward Primer", "Reverse Primer", "QC Primer1", "QC Primer2"
            pid = property.id
            inventory_check_result = inventory_check pid, sample_type: "Primer", inventory_types: ["Primer Aliquot", "Primer Stock"]
            inventory_check_result[:errors].collect! do |err|
              "#{sample_name}'s #{field} #{err}"
            end
            warnings.push inventory_check_result[:errors]
            ids_to_make.concat inventory_check_result[:ids_to_make]
          when "Overhang Sequence", "Anneal Sequence"
            warnings.push "#{sample_name} #{field} requires nonempty string" unless property.length > 0
          when "T Anneal"
            warnings.push "#{sample_name} #{field} requires number greater than 40" unless property > 40
          when "Template"
            template_stock_hash = {
              "Plasmid" => ["1 ng/µL Plasmid Stock", "Plasmid Stock", "Gibson Reaction Result"],
              "Fragment" => ["1 ng/µL Fragment Stock", "Fragment Stock" ],
              "E coli strain" => ["E coli Lysate", "Genome Prep"],
              "Yeast Strain" => ["Lysate", "Yeast cDNA"]
            }
            template_stocks = []
            template = property
            template_stock_hash[template.sample_type.name].each do |container|
              template_stocks.push template.in(container)[0]
            end
            template_stocks.compact!
            warnings.push(template_stock_hash[template.sample_type.name].join(" or ").to_s + " is required for #{sample_name} #{field}") if template_stocks.empty?
          when "Length"
            warnings.push "Length greater than 0 is required for #{sample_name}" unless property > 0
          when "Bacterial Marker", "Yeast Marker"
            warnings.push "Nonempty string is required for #{sample_name} #{field}" unless property.length > 0
          when "Parent"
            yid = property.id
            inventory_check_result = inventory_check yid, sample_type: "Yeast Strain", inventory_types: ["Yeast Competent Cell", "Yeast Competent Aliquot"]
            inventory_check_result[:errors].collect! do |err|
              "#{sample_name}'s #{field} #{err}"
            end
            warnings.push inventory_check_result[:errors]
            ids_to_make.concat inventory_check_result[:ids_to_make]
          end # case
        else
          warnings.push "#{field} is required for #{sample_name}"
        end # if properties[field]
        if params[:assert_logic] == "and"
          puts warnings
          errors.concat warnings.flatten
        elsif params[:assert_logic] == "or"
          if warnings.length == assert_properties.length
            errors.push warnings.flatten.join(" or ")
          end
        end
      end # assert_properties.each
    end # ids.each
    errors.uniq!
    ids_to_make.uniq!
    return {
      errors: errors,
      ids_to_make: ids_to_make
    }
  end

  def task_status p={}
    params = ({ group: "", name: "", notification: "off" }).merge p
    raise "Supply a Task name for the task_status function as tasks_status name: task_name" if params[:name].empty?
    tasks_to_process = find(:task,{ task_prototype: { name: params[:name] } }).select {
    |t| %w[waiting ready].include? t.status }
    # filter out tasks based on group input
    if !params[:group].empty?
      user_group = params[:group] == "technicians"? "cloning": params[:group]
      group_info = Group.find_by_name(user_group)
      tasks_to_process.select! { |t| t.user.member? group_info.id }
    end

    # array of object_type_names and sample_type_names
    object_type_names = ObjectType.all.collect { |i| i.name }.push "Item"
    sample_type_names = SampleType.all.collect { |i| i.name }.push "Sample"
    # an array to store new tasks got automatically created.
    new_task_ids = []
    # cycling through tasks_to_process to make sure tasks inputs are valid
    tasks_to_process.each do |t|
      #To do: check array sizes equal? first
      errors = []
      notifs = []
      argument_lengths = []
      t.spec.each do |argument, ids|
        argument = argument.to_s
        variable_name = argument.split(' ')[0]
        argument.slice!(argument.split(' ')[0])
        argument.slice!(0) # remove white space in the beginning
        inventory_types = argument.split('|')
        inventory_types.uniq!
        argument_lengths.push ids.length if ids.is_a? Array
        ids = [ids] unless ids.is_a? Array
        ids.flatten!
        ids.uniq!
        # processing sample type or inventory type check
        if inventory_types.any?
          if (object_type_names & inventory_types).sort == inventory_types.sort
            item_or_sample = :item
          elsif (sample_type_names & inventory_types).sort == inventory_types.sort
            item_or_sample = :sample
          else
            item_or_sample = ""
            errors.push "Please check your task prototype definition."
          end
          unless item_or_sample.empty?
            ids.each do |id|
              if !find(item_or_sample, id: id)[0]
                errors.push "Can not find #{item_or_sample} #{id}."
              elsif !inventory_type_check(inventory_types, item_or_sample, id)
                errors.push "#{item_or_sample} #{id} is not #{inventory_types.join(" or ")}."
              end
            end # ids
          end # unless
        end # if inventory_types.any?
        # processing sample properties or inventory check when id is sample
        # only start processing in this level when there is no errors in previous type checking
        if errors.empty?
          case variable_name
          when "primer_ids"
            if params[:name] == "Primer Order"
              errors.concat sample_check(ids, sample_type: "Primer", assert_property: ["Overhang Sequence", "Anneal Sequence"], assert_logic: "or")[:errors]
            else  # for Sequencing, Plasmid Verification
              inventory_check_result = inventory_check ids, sample_type: "Primer", inventory_types: ["Primer Aliquot", "Primer Stock"]
              errors.concat inventory_check_result[:errors]
              new_tasks = create_new_tasks(inventory_check_result[:ids_to_make], task_name: "Primer Order", user_id: t.user.id)
            end
          when "fragments"
            if params[:name] == "Fragment Construction"
              sample_check_result = sample_check(ids, sample_type: "Fragment", assert_property: ["Forward Primer","Reverse Primer","Template","Length"])
              errors.concat sample_check_result[:errors]
              new_tasks = create_new_tasks(sample_check_result[:ids_to_make], task_name: "Primer Order", user_id: t.user.id)
            elsif params[:name] == "Gibson Assembly"
              inventory_check_result = inventory_check(ids, sample_type: "Fragment", inventory_types: "Fragment Stock")
              errors.concat inventory_check_result[:errors]
              new_tasks = create_new_tasks(inventory_check_result[:ids_to_make], task_name: "Fragment Construction", user_id: t.user.id)
              errors.concat sample_check(ids, sample_type: "Fragment", assert_property: "Length")[:errors]
            end
          when "plate_ids", "glycerol_stock_ids"
            sample_ids = ids.collect { |id| find(:item, id: id)[0].sample.id }
            errors.concat sample_check(sample_ids, sample_type: "Plasmid", assert_property: "Bacterial Marker")[:errors]
          when "num_colonies"
            ids.each do |id|
              errors.push "A number between 0,10 is required for num_colonies" unless id.between?(0, 10)
            end
          when "plasmid"
            errors.concat sample_check(ids, sample_type: "Plasmid", assert_property: "Bacterial Marker")[:errors]
          when "yeast_transformed_strain_ids"
            sample_check_result = sample_check(ids, sample_type: "Yeast Strain", assert_property: "Parent")
            errors.concat sample_check_result[:errors]
            new_tasks = create_new_tasks(sample_check_result[:ids_to_make], task_name: "Yeast Competent Cell", user_id: t.user.id)
            errors.concat sample_check(ids, sample_type: "Yeast Strain", assert_property: ["Integrant", "Plasmid"], assert_logic: "or")[:errors]
          when "yeast_plate_ids"
            sample_ids = ids.collect { |id| find(:item, id: id)[0].sample.id }
            errors.concat sample_check(sample_ids, sample_type: "Yeast Strain", assert_property: ["QC Primer1", "QC Primer2"])[:errors]
          when "yeast_strain_ids"
            ids_to_make = []
            ids.each do |id|
              yeast_strain = find(:sample, id: id)[0]
              if (collection_type_contain_has_colony id, "Divided Yeast Plate").empty?
                errors.push "Yeast Strain #{yeast_strain.name} needs a Divided Yeast Plate (Collection)."
                glycerol_stock = yeast_strain.in("Yeast Glycerol Stock")[0]
                if glycerol_stock
                  ids_to_make.push glycerol_stock
                else
                  errors.push "Yeast Strain #{yeast_strain.name} needs a Yeast Glycerol Stock to automatically submit Streak Plate tasks"
                end
              end
            end # ids
            ids_to_make.uniq!
            new_tasks = create_new_tasks(ids_to_make, task_name: "Streak Plate", user_id: t.user.id)
          end # case
          if new_tasks # when new_tasks are created
            new_task_ids.concat new_tasks[:new_task_ids]
            notifs.concat new_tasks[:notifs]
          end
        end # errors.empty?
      end # t.spec.each
      argument_lengths.uniq!
      errors.push "Array argument needs to have the same size." if argument_lengths.length != 1  # check if array sizes are the same, for example, the Plasmid Verification and Sequencing.
      if errors.any?
        errors.each { |error| t.notify "[Error] #{error}", job_id: jid }
        set_task_status(t, "waiting") unless t.status == "waiting"
      else
        set_task_status(t, "ready") unless t.status == "ready"
      end
      if notifs.any?
        notifs.each { |notif| t.notify "[Notif] #{notif}", job_id: jid }
      end
    end # tasks_to_process

    task_status_hash = {
      waiting_ids: (tasks_to_process.select { |t| t.status == "waiting" })
      .collect { |t| t.id },
      ready_ids: (tasks_to_process.select { |t| t.status == "ready" })
      .collect {|t| t.id},
      new_task_ids: new_task_ids
    }
    return task_status_hash
  end

  # create new tasks for fragment construction, primer order, yeast competent cell
  def create_new_tasks ids, p={}
    params = ({ task_name: "", user_id: nil }).merge p
    ids = [ids] unless ids.is_a? Array
    new_task_ids = []
    notifs = [] # to store all notifications
    task_prototype_name = params[:task_name]
    tp = TaskPrototype.where(name: task_prototype_name)[0]
    tp_name = tp.name.split(" ").collect { |i| i.downcase }.join("_")
    task_type_argument_hash = {
      "Fragment Construction" => "fragments Fragment",
      "Primer Order" => "primer_ids Primer",
      "Yeast Competent Cell" => "yeast_strain_ids Yeast Strain",
      "Streak Plate" => "item_ids Yeast Glycerol Stock|Yeast Plate",
      "Discard Item" => "item_ids Item",
      "Glycerol Stock" => "item_ids Yeast Plate|Yeast Overnight Suspension|TB Overnight of Plasmid|Overnight suspension"
    }
    sample_input_task_names = ["Fragment Construction", "Primer Order", "Yeast Competent Cell"]
    item_input_task_names = ["Streak Plate", "Discard Item", "Glycerol Stock"]
    ids.each do |id|
      if sample_input_task_names.include? task_prototype_name
        sample = find(:sample, id: id)[0]
        auto_create_task_name = "#{sample.name}_#{tp_name}"
      elsif item_input_task_names.include? task_prototype_name
        item = find(:item, id: id)[0]
        sample = item.sample
        item_type_name = item.object_type.name.split(" ").collect { |i| i.downcase }.join("_")
        auto_create_task_name = "#{sample.name}_#{item_type_name}_#{item.id}_#{tp_name}"
      end
      task = find(:task, name: auto_create_task_name)[0]
      if task
        if ["done", "received and stocked", "imaged and stored in fridge"].include? task.status
          set_task_status(task, "waiting")
          notifs.push "#{auto_create_task_name} changed status to waiting to make more."
          new_task_ids.push task.id
        elsif ["failed","canceled"].include? task.status
          notifs.push "#{auto_create_task_name} was failed or canceled. You need to manually switch the status if you want to remake."
        else
          notifs.push "#{auto_create_task_name} is already in the #{task_prototype_name} workflow."
        end
      else
        t = Task.new(name: auto_create_task_name, specification: { task_type_argument_hash[task_prototype_name] => [ id ] }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: params[:user_id] ||sample.user.id)
        t.save
        notifs.push "#{auto_create_task_name} is automatically submitted to #{task_prototype_name} workflow."
        new_task_ids.push t.id
      end
    end
    return {
      new_task_ids: new_task_ids,
      notifs: notifs
    }
  end

  def sequencing_verification_task_processing p={}
    params = ({ group: "" }).merge p
    tasks_to_process = find(:task, { task_prototype: { name: "Sequencing Verification" } })
    if !params[:group].empty?
      user_group = params[:group] == "technicians"? "cloning": params[:group]
      group_info = Group.find_by_name(user_group)
      tasks_to_process.select! { |t| t.user.member? group_info.id }
    end
    new_task_ids = []
    status_to_process = ["sequence correct", "sequence correct but keep plate", "sequence correct but redundant", "sequence wrong"]
    tasks_to_process.select! { |t| status_to_process.include? t.status }
    tasks_to_process.each do |t|
      discard_item_ids = [] # list of items to discard
      stock_item_ids = [] # list of items to glycerol stock
      plasmid_stock_id = t.simple_spec[:plasmid_stock_ids][0]
      overnight_id = t.simple_spec[:overnight_ids][0]
      overnight = find(:item, id: overnight_id)[0]
      plate_id, gibson_reaction_result_ids = 0,[]
      if overnight
        plate_id = overnight.datum[:from]
        gibson_reaction_results = overnight.sample.in("Gibson Reaction Result")
        gibson_reaction_result_ids = gibson_reaction_results.collect { |g| g.id }
      end
      case t.status
      when "sequence correct"
        discard_item_ids.concat gibson_reaction_result_ids
        discard_item_ids.push plate_id if find(:item, id: plate_id)[0]
        stock_item_ids.push overnight_id
      when "sequence correct but keep plate"
        stock_item_ids.push overnight_id
      when "sequence correct but redundant", "sequence wrong"
        discard_item_ids.concat [plasmid_stock_id, overnight_id]
      end
      # create new tasks
      new_discard_tasks = create_new_tasks(discard_item_ids, task_name: "Discard Item", user_id: t.user.id)
      new_stock_tasks = create_new_tasks(stock_item_ids, task_name: "Glycerol Stock", user_id: t.user.id)
      notifs = new_discard_tasks[:notifs] + new_stock_tasks[:notifs]
      new_task_ids.concat new_discard_tasks[:new_task_ids] + new_stock_tasks[:new_task_ids]
      if notifs.any?
        notifs.each { |notif| t.notify "[Notif] #{notif}", job_id: jid }
      end
      t.status = "done"
      t.save
    end
    return new_task_ids
  end

  def show_tasks_table ids
    if ids.any?
      new_task_table = task_info_table(ids)
      show {
        title "New tasks"
        note "The following tasks are automatically created or status adjusted."
        table new_task_table
      }
    end
  end

  def arguments
    {
      io_hash: {},
      debug_mode: "Yes",
      task_name: "Fragment Construction",
      group: "technicians"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", task_name: "", task_ids: [], size: 0 }.merge io_hash
    io_hash_default = Hash.new(Array.new)
    io_hash = io_hash_default.merge io_hash  # make io_hash default value []

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # automatic task submissions

    if ["Discard Item", "Glycerol Stock"].include? io_hash[:task_name]
      show_tasks_table(sequencing_verification_task_processing group: io_hash[:group])
    end

    # process task_status
    tasks = task_status name: io_hash[:task_name], group: io_hash[:group]

    # show the users about newly created and adjusted tasks
    show_tasks_table tasks[:new_task_ids]

    wating_tab = task_info_table tasks[:waiting_ids]
    ready_tab = task_info_table tasks[:ready_ids]

    show {
      title "Task status"
      note "For #{io_hash[:task_name]} tasks that belong to #{io_hash[:group]}:"
      note "Waiting tasks quantity: #{tasks[:waiting_ids].length}"
      table wating_tab
      note "Ready tasks quantity: #{tasks[:ready_ids].length}"
      table ready_tab
    }

    # task sizes limit choose
    io_hash[:task_ids] = task_choose_limit(tasks[:ready_ids], io_hash[:task_name])

    case io_hash[:task_name]

    when "Glycerol Stock"
      io_hash = { overnight_ids: [], item_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.simple_spec[:item_ids].each do |id|
          if find(:item, id: id)[0].object_type.name.downcase.include? "overnight"
            io_hash[:overnight_ids].push id
          elsif find(:item, id: id)[0].object_type.name.downcase.include? "plate"
            io_hash[:item_ids].push id
          end
        end
      end
      io_hash[:size] = io_hash[:overnight_ids].length + io_hash[:item_ids].length

    when "Streak Plate"
      io_hash = { yeast_plate_ids:[], yeast_glycerol_stock_ids:[] }.merge io_hash
      io_hash[:yeast_glycerol_stock_ids] = []
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.simple_spec[:item_ids].each do |id|
          if find(:item, id: id)[0].object_type.name == "Yeast Glycerol Stock"
            io_hash[:yeast_glycerol_stock_ids].push id
          elsif ["Yeast Plate"].include? find(:item, id: id)[0].object_type.name
            io_hash[:yeast_plate_ids].concat task.simple_spec[:item_ids]
          end
        end
      end
      io_hash[:size] = io_hash[:yeast_glycerol_stock_ids].length + io_hash[:yeast_plate_ids].length

    when "Gibson Assembly"
      io_hash = { fragment_ids: [], plasmid_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:fragment_ids].push task.simple_spec[:fragments]
        io_hash[:plasmid_ids].push task.simple_spec[:plasmid]
      end
      io_hash[:size] = io_hash[:plasmid_ids].length

    when "Plasmid Verification"
      io_hash = { num_colonies: [], plate_ids: [], primer_ids: [], initials: [], glycerol_stock_ids: [] }.merge io_hash

      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:plate_ids].concat task.simple_spec[:plate_ids]
        io_hash[:num_colonies].concat task.simple_spec[:num_colonies]
        io_hash[:primer_ids].concat task.simple_spec[:primer_ids]
      end
      # Add plasmid extraction tasks here to do overnight and miniprep in one batch
      plasmid_extraction_tasks = task_status name: "Plasmid Extraction", group: io_hash[:group]
      io_hash[:plasmid_extraction_task_ids] = task_choose_limit(plasmid_extraction_tasks[:ready_ids], "Plasmid Extraction")
      io_hash[:plasmid_extraction_task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:glycerol_stock_ids].concat task.simple_spec[:glycerol_stock_ids]
      end
      io_hash[:task_ids].concat io_hash[:plasmid_extraction_task_ids]
      io_hash[:size] = io_hash[:num_colonies].inject { |sum, n| sum + n } || 0 + io_hash[:glycerol_stock_ids].length

    when "Primer Order", "Discard Item", "Yeast Competent Cell", "Fragment Construction"
      # a general task processing script only works for those tasks with one variable_name
      io_hash[:task_ids].each_with_index do |tid, idx|
        task = find(:task, id: tid)[0]
        task.simple_spec.each do |variable_name, ids|
          variable_name = :fragment_ids if variable_name == :fragments
          io_hash[variable_name] = [] if idx == 0
          io_hash[variable_name].concat ids
          if idx == io_hash[:task_ids].length - 1
            io_hash[variable_name].uniq!
            io_hash[:size] = io_hash[variable_name].length
          end
        end
      end

      io_hash[:volume] = 2 if io_hash[:task_name] == "Yeast Competent Cell"

    when "Yeast Transformation"
      io_hash = { yeast_transformed_strain_ids: [], plasmid_stock_ids: [], yeast_parent_strain_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:yeast_transformed_strain_ids].concat task.simple_spec[:yeast_transformed_strain_ids]
        io_hash[:plasmid_stock_ids].concat task.simple_spec[:yeast_transformed_strain_ids].collect { |yid| choose_stock(find(:sample, id: yid)[0].properties["Integrant"]) }
        io_hash[:yeast_parent_strain_ids].concat task.simple_spec[:yeast_transformed_strain_ids].collect { |yid| find(:sample, id: yid)[0].properties["Parent"].id }
      end
      io_hash[:size] = io_hash[:yeast_transformed_strain_ids].length

    when "Yeast Strain QC"
      io_hash = { yeast_plate_ids: [], num_colonies: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.simple_spec[:yeast_plate_ids].each_with_index do |id, idx|
          if !(io_hash[:yeast_plate_ids].include? id)
            io_hash[:yeast_plate_ids].push id
            io_hash[:num_colonies].push task.simple_spec[:num_colonies][idx]
          end
        end
      end
      io_hash[:gel_band_verify] = "Yes"
      io_hash[:size] = io_hash[:num_colonies].inject { |sum, n| sum + n }

    when "Yeast Mating"
      io_hash = { yeast_mating_strain_ids: [], yeast_selective_plate_types: [], user_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:yeast_mating_strain_ids].push task.simple_spec[:yeast_mating_strain_ids]
        io_hash[:yeast_selective_plate_types].push task.simple_spec[:yeast_selective_plate_type]
        io_hash[:user_ids].push task.user.id
      end
      io_hash[:size] = io_hash[:yeast_mating_strain_ids].length

    else
      show {
        title "Under development"
        note "The input checking Protocol for this task #{io_hash[:task_name]} is still under development."
      }
    end

    tasks_tab = task_info_table(io_hash[:task_ids])

    show {
      title "Tasks inputs processed!"
      note "#{io_hash[:task_name]} tasks inputs have been successfully processed!"
      if io_hash[:task_ids].length > 0
        note "The following tasks inputs has been processed, batched and returned as outputs. The total batch size is #{io_hash[:size]}."
        table tasks_tab
      else
        note "No task's input is returned as outputs"
      end
    }

    return { io_hash: io_hash }
  end

end
