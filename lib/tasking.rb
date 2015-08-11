module Tasking
  # supply a poly fit data model name and size of the reaction, predit the time it will take
  def time_prediction size, model_name
    if size == 0
      return 0
    end
    model_data = find(:sample, name: model_name)[0].properties["Model"]
    model_array = model_data.split(",")
    n = model_array.length - 1
    time = 0
    model_array.each_with_index do |p, idx|
      time += p.to_f * size ** (n - idx)
    end
    return time.round(0)
  end

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
      tab.push [ tid, task_prototype_html_link(task.task_prototype.name), task_html_link(task), task.user.name, task_size(tid) ]
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
    sizes = [0]
    task_ids.each do |id|
      sizes.push task_size(id) + sizes[-1]
    end
    if sizes == [0]
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
    return task_ids.take(limit_idx)
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
    when "Ecoli Transformation"
      size = task.simple_spec[:plasmid_item_ids].length
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

  # return a descriptive sample with html link
  def sample_html_link sample
    return "#{sample.sample_type.name} " + "<a href='/samples/#{sample.id}'>#{sample.id}: #{sample.name}</a>".html_safe
  end

  # return a link for task
  def task_html_link task
    return "<a href='/tasks/#{task.id}'>#{task.name}</a>".html_safe
  end

  # return a link for task_prototype task_prototype_name
  def task_prototype_html_link task_prototype_name
    tp = TaskPrototype.where(name: task_prototype_name)[0]
    return "<a href='/tasks?task_prototype_id=#{tp.id}'>#{task_prototype_name}</a>".html_safe
  end

  def item_or_sample_html_link id, item_or_sample
    return "<a href='/#{item_or_sample}s/#{id}'>#{id}</a>".html_safe
  end

  def indefinite_articlerize(params_word)
      %w(a e i o u).include?(params_word[0].downcase) ? "an" : "a"
  end

  # returns errors of inventory_check and possible needs for submitting new tasks
  def inventory_check ids, p={}
    params = ({ inventory_types: "" }).merge p
    ids = [ids] if ids.is_a? Numeric
    ids_to_make = [] # put the list of sample ids that need inventory_type to be made
    inventory_types = params[:inventory_types]
    inventory_types = [inventory_types] if inventory_types.is_a? String
    errors = []
    ids.each do |id|
      sample = find(:sample, id: id)[0]
      sample_name = sample_html_link sample
      warning = []
      inventory_types.each do |inventory_type|
        if sample.in(inventory_type).empty?
          warning.push "#{sample_name} does not have a #{inventory_type}."
        end
      end
      if warning.length == inventory_types.length
        errors.push "#{sample_name} requires #{indefinite_articlerize(inventory_types[0])} #{inventory_types.join(" or ")}."
        ids_to_make.push id
      end
    end
    return {
      errors: errors,
      ids_to_make: ids_to_make
    }
  end

  def sample_check ids, p={}
    params = ({ assert_property: [], assert_logic: "and" }).merge p
    ids = [ids] if ids.is_a? Numeric
    assert_properties = params[:assert_property]
    assert_properties = [assert_properties] unless assert_properties.is_a? Array
    if assert_properties.empty?
      return nil
    end
    errors = []
    ids_to_make = [] # ids that require inventory to be made through other tasks
    ids.each do |id|
      sample = find(:sample, id: id)[0]
      sample_name = sample_html_link sample
      properties = sample.properties.deep_dup
      assert_properties.each do |field|
        warnings = [] # to store temporary errors
        if properties[field]
          property = properties[field]
          case field
          when "Forward Primer", "Reverse Primer", "QC Primer1", "QC Primer2"
            pid = property.id
            inventory_check_result = inventory_check pid, inventory_types: ["Primer Aliquot", "Primer Stock"]
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
            inventory_check_result = inventory_check yid, inventory_types: ["Yeast Competent Cell", "Yeast Competent Aliquot"]
            inventory_check_result[:errors].collect! do |err|
              "#{sample_name}'s #{field} #{err}"
            end
            warnings.push inventory_check_result[:errors]
            ids_to_make.concat inventory_check_result[:ids_to_make]
          when "Integrant"
            pid = property.id
            inventory_check_result = inventory_check pid, inventory_types: "#{find(:sample, id: pid)[0].sample_type.name} Stock"
            inventory_check_result[:errors].collect! do |err|
              "#{sample_name}'s #{field} #{err}"
            end
            warnings.push inventory_check_result[:errors]
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
                errors.push "#{item_or_sample.to_s.capitalize} #{item_or_sample_html_link id,item_or_sample} is not #{indefinite_articlerize(inventory_types[0])} #{inventory_types.join(" or ")}."
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
              errors.concat sample_check(ids, assert_property: ["Overhang Sequence", "Anneal Sequence"], assert_logic: "or")[:errors]
            else  # for Sequencing, Plasmid Verification
              inventory_check_result = inventory_check ids, inventory_types: ["Primer Aliquot", "Primer Stock"]
              errors.concat inventory_check_result[:errors]
              new_tasks = create_new_tasks(inventory_check_result[:ids_to_make], task_name: "Primer Order", user_id: t.user.id)
            end
          when "fragments"
            if params[:name] == "Fragment Construction"
              sample_check_result = sample_check(ids, assert_property: ["Forward Primer","Reverse Primer","Template","Length"])
              errors.concat sample_check_result[:errors]
              new_tasks = create_new_tasks(sample_check_result[:ids_to_make], task_name: "Primer Order", user_id: t.user.id)
            elsif params[:name] == "Gibson Assembly"
              inventory_check_result = inventory_check(ids, inventory_types: "Fragment Stock")
              errors.concat inventory_check_result[:errors]
              new_tasks = create_new_tasks(inventory_check_result[:ids_to_make], task_name: "Fragment Construction", user_id: t.user.id)
              errors.concat sample_check(ids, assert_property: "Length")[:errors]
            end
          when "plate_ids", "glycerol_stock_ids", "plasmid_item_ids"
            sample_ids = ids.collect { |id| find(:item, id: id)[0].sample.id }
            errors.concat sample_check(sample_ids, assert_property: "Bacterial Marker")[:errors]
          when "num_colonies"
            ids.each do |id|
              errors.push "A number between 0,10 is required for num_colonies" unless id.between?(0, 10)
            end
          when "plasmid"
            errors.concat sample_check(ids, assert_property: "Bacterial Marker")[:errors]
          when "yeast_transformed_strain_ids"
            sample_check_result = sample_check(ids, assert_property: "Parent")
            errors.concat sample_check_result[:errors]
            new_tasks = create_new_tasks(sample_check_result[:ids_to_make], task_name: "Yeast Competent Cell", user_id: t.user.id)
            errors.concat sample_check(ids, assert_property: "Integrant")[:errors]
          when "yeast_plate_ids"
            sample_ids = ids.collect { |id| find(:item, id: id)[0].sample.id }
            sample_check_result = sample_check(sample_ids, assert_property: ["QC Primer1", "QC Primer2"])
            errors.concat sample_check_result[:errors]
            new_tasks = create_new_tasks(sample_check_result[:ids_to_make], task_name: "Primer Order", user_id: t.user.id)
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
      task_prototype_name_link = task_prototype_html_link task_prototype_name
      if task
        auto_create_task_name_link = task_html_link task
        if ["done", "received and stocked", "imaged and stored in fridge"].include? task.status
          set_task_status(task, "waiting")
          notifs.push "#{auto_create_task_name_link} changed status to waiting to make more."
          new_task_ids.push task.id
        elsif ["failed","canceled"].include? task.status
          notifs.push "#{auto_create_task_name_link} was failed or canceled. You need to manually switch the status if you want to remake."
        else
          notifs.push "#{auto_create_task_name_link} is already in the #{task_prototype_name_link} Tasks."
        end
      else
        t = Task.new(name: auto_create_task_name, specification: { task_type_argument_hash[task_prototype_name] => [ id ] }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: params[:user_id] ||sample.user.id)
        t.save
        auto_create_task_name_link = task_html_link t
        notifs.push "#{auto_create_task_name_link} is automatically submitted to #{task_prototype_name_link} Tasks."
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

end
