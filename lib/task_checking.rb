include Krill::Base

def after_save
  task_status_check self
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
  return "#{sample.sample_type.name} " + "<a href='/samples/#{sample.id}' target='_top'>#{sample.name}</a>".html_safe
end

# return a link for task
def task_html_link task
  return "<a href='/tasks/#{task.id}' target='_top'>#{task.name}</a>".html_safe
end

# return a link for task_prototype task_prototype_name
def task_prototype_html_link task_prototype_name
  tp = TaskPrototype.where(name: task_prototype_name)[0]
  return "<a href='/tasks?task_prototype_id=#{tp.id}' target='_top'>#{task_prototype_name}</a>".html_safe
end

def item_or_sample_html_link id, item_or_sample
  return "<a href='/#{item_or_sample}s/#{id}' target='_top'>#{id}</a>".html_safe
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
    warnings = [] # to store temporary errors for each id
    assert_properties.each do |field|
      sample_field_name = "#{sample_name}'s #{field}"
      if properties[field]
        property = properties[field]
        case field
        when "Forward Primer", "Reverse Primer", "QC Primer1", "QC Primer2"
          pid = property.id
          inventory_check_result = inventory_check pid, inventory_types: ["Primer Aliquot", "Primer Stock"]
          inventory_check_result[:errors].collect! do |err|
            "#{sample_field_name} #{err}"
          end
          warnings.push inventory_check_result[:errors].collect! { |error| "[Notif] #{error}"}
          ids_to_make.concat inventory_check_result[:ids_to_make]
        when "Overhang Sequence", "Anneal Sequence"
          warnings.push "#{sample_field_name} requires nonempty string" unless property.length > 0
        when "T Anneal"
          warnings.push "#{sample_field_name} requires number greater than 40" unless property > 40
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
          warnings.push("#{sample_field_name} requires #{template_stock_hash[template.sample_type.name].join(' or ')}.") if template_stocks.empty?
        when "Length"
          warnings.push "#{sample_field_name} requires a number greater than 0." unless property > 0
        when "Bacterial Marker", "Yeast Marker"
          warnings.push "#{sample_field_name} requires a nonempty string." unless property.length > 0
        when "Parent"
          yid = property.id
          inventory_check_result = inventory_check yid, inventory_types: ["Yeast Competent Cell", "Yeast Competent Aliquot"]
          inventory_check_result[:errors].collect! do |err|
            "#{sample_field_name} #{err}"
          end
          warnings.push inventory_check_result[:errors].collect! { |error| "[Notif] #{error}"}
          ids_to_make.concat inventory_check_result[:ids_to_make]
        when "Integrant"
          pid = property.id
          integrant_sample = find(:sample, id: pid)[0]
          inventory_check_result = inventory_check pid, inventory_types: "#{integrant_sample.sample_type.name} Stock"
          inventory_check_result[:errors].collect! do |err|
            "#{sample_field_name} #{err}"
          end
          if integrant_sample.sample_type.name == "Fragment"
            warnings.push inventory_check_result[:errors].collect! { |error| "[Notif] #{error}"}
            ids_to_make.concat inventory_check_result[:ids_to_make]
          else
            warnings.push inventory_check_result[:errors]
          end
        end # case
      else
        warnings.push "#{sample_field_name} is required."
      end # if properties[field]
    end # assert_properties.each
    if params[:assert_logic] == "and"
      errors.concat warnings.flatten
    elsif params[:assert_logic] == "or"
      if warnings.length == assert_properties.length
        errors.push warnings.flatten.join(" or ")
      end
    end
  end # ids.each
  errors.uniq!
  ids_to_make.uniq!
  return {
    errors: errors,
    ids_to_make: ids_to_make
  }
end

def task_status_check t
  # array of object_type_names and sample_type_names
  object_type_names = ObjectType.all.collect { |i| i.name }.push "Item"
  sample_type_names = SampleType.all.collect { |i| i.name }.push "Sample"
  # an array to store new tasks got automatically created.
  new_task_ids = []
  errors = []
  notifs = []
  argument_lengths = []
  if t.task_prototype.name == "Sequencing Verification"
    sequencing_verification_results = sequencing_verification_task_processing t
    new_task_ids.concat sequencing_verification_results[:new_task_ids]
    notifs.concat sequencing_verification_results[:notifs]
  elsif ["waiting", "ready"].include? t.status
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
        new_tasks = {}
        case variable_name
        when "primer_ids"
          if t.task_prototype.name == "Primer Order"
            errors.concat sample_check(ids, assert_property: ["Overhang Sequence", "Anneal Sequence"], assert_logic: "or")[:errors]
          else  # for Sequencing, Plasmid Verification
            inventory_check_result = inventory_check ids, inventory_types: ["Primer Aliquot", "Primer Stock"]
            errors.concat inventory_check_result[:errors].collect! { |error| "[Notif] #{error}"}
            new_tasks["Primer Order"] = inventory_check_result[:ids_to_make]
          end
        when "fragments"
          if t.task_prototype.name == "Fragment Construction"
            sample_check_result = sample_check(ids, assert_property: ["Forward Primer","Reverse Primer","Template","Length"])
            errors.concat sample_check_result[:errors]
            new_tasks["Primer Order"] = sample_check_result[:ids_to_make]
          elsif t.task_prototype.name == "Gibson Assembly"
            inventory_check_result = inventory_check(ids, inventory_types: "Fragment Stock")
            errors.concat inventory_check_result[:errors].collect! { |error| "[Notif] #{error}"}
            new_tasks["Fragment Construction"] = inventory_check_result[:ids_to_make]
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
          new_tasks["Yeast Competent Cell"] = sample_check_result[:ids_to_make]
          integrant_check_result = sample_check(ids, assert_property: "Integrant")
          errors.concat integrant_check_result[:errors]
          new_tasks["Fragment Construction"] = integrant_check_result[:ids_to_make]
        when "yeast_plate_ids"
          sample_ids = ids.collect { |id| find(:item, id: id)[0].sample.id }
          sample_check_result = sample_check(sample_ids, assert_property: ["QC Primer1", "QC Primer2"])
          errors.concat sample_check_result[:errors]
          new_tasks["Primer Order"] = sample_check_result[:ids_to_make]
        when "yeast_mating_strain_ids"
          inventory_check_result = inventory_check(ids, inventory_types: "Yeast Glycerol Stock")
          errors.concat inventory_check_result[:errors]
        when "yeast_strain_ids"
          ids_to_make = []
          ids.each do |id|
            yeast_strain = find(:sample, id: id)[0]
            if (collection_type_contain_has_colony id, "Divided Yeast Plate").empty?
              errors.push "[Notif] Yeast Strain #{yeast_strain.name} needs a Divided Yeast Plate (Collection)."
              glycerol_stock = yeast_strain.in("Yeast Glycerol Stock")[0]
              if glycerol_stock
                ids_to_make.push glycerol_stock.id
              else
                errors.push "Yeast Strain #{yeast_strain.name} needs a Yeast Glycerol Stock to automatically submit Streak Plate tasks"
              end
            end
          end # ids
          new_tasks["Streak Plate"] = ids_to_make
        end # case
        new_tasks.each do |task_type_name, ids|
          created_tasks = create_new_tasks(ids, task_name: task_type_name, user_id: t.user.id)
          new_task_ids.concat created_tasks[:new_task_ids]
          notifs.concat created_tasks[:notifs]
        end
      end # errors.empty?
    end # t.spec.each
    argument_lengths.uniq!
    errors.push "Array argument needs to have the same size." if argument_lengths.length != 1  # check if array sizes are the same, for example, the Plasmid Verification and Sequencing.
    errors.push "yeast_mating_strain_ids needs to have the size of 2." if t.task_prototype.name == "Yeast Mating" && argument_lengths != [2] # check if input size is 2 for yeast mating.
    job_id = defined?(jid) ? jid : nil
    if errors.any?
      warnings = errors.select { |error| error.include? "[Notif]" }
      errors = errors - warnings
      warnings = warnings - t.notifications.collect { |notif| notif.content }
      warnings.each { |warning| t.notify warning, job_id: job_id }
      errors.each { |error| t.notify "[Error] #{error}", job_id: job_id }
      unless t.status == "waiting"
        t.status = "waiting"
        t.save
      end
    else
      unless t.status == "ready"
        t.status = "ready"
        t.notify "This task has passed input checking and ready to go!", job_id: job_id
        t.save
      end
    end
  end # end if t.task_prototype.name == "Sequencing Verification"
  notifs.collect! { |notif| "[Notif] #{notif}" }
  notifs = notifs - t.notifications.collect { |notif| notif.content }
  if notifs.any?
    notifs.each { |notif| t.notify notif, job_id: job_id }
  end

  return {
    status: t.status,
    new_task_ids: new_task_ids
  }
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
    "Fragment Construction" => { spec: "fragments Fragment", output: "Fragment Stock" },
    "Primer Order" => { spec: "primer_ids Primer", output: "Primer Aliquot and Primer Stock" },
    "Yeast Competent Cell" => { spec: "yeast_strain_ids Yeast Strain", output: "Yeast Competent Cell" },
    "Streak Plate" => { spec: "item_ids Yeast Glycerol Stock|Yeast Plate", output: "Divided Yeast Plate" },
    "Discard Item" => { spec: "item_ids Item", output: "item deleted" },
    "Glycerol Stock" => { spec: "item_ids Yeast Plate|Yeast Overnight Suspension|TB Overnight of Plasmid|Overnight suspension", output: "Glycerol Stock" },
    "Yeast Transformation" => { spec: "yeast_transformed_strain_ids Yeast Strain", output: "Yeast Plate" }
  }
  sample_input_task_names = ["Fragment Construction", "Primer Order", "Yeast Competent Cell", "Yeast Transformation"]
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
        task.status = "waiting"
        task.save
        task.notify "Status changed back to waiting to make more."
        notifs.push "#{auto_create_task_name_link} changed status to waiting to make more."
        new_task_ids.push task.id
      elsif ["failed","canceled"].include? task.status
        notifs.push "#{auto_create_task_name_link} was failed or canceled. You need to manually switch the status if you want to remake."
      else
        notifs.push "#{auto_create_task_name_link} is in the #{task_prototype_name_link} Tasks to produce #{task_type_argument_hash[task_prototype_name][:output]}."
      end
    else
      t = Task.new(name: auto_create_task_name, specification: { task_type_argument_hash[task_prototype_name][:spec] => [ id ] }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: params[:user_id] ||sample.user.id)
      t.save
      auto_create_task_name_link = task_html_link t
      notifs.push "#{auto_create_task_name_link} is automatically submitted to #{task_prototype_name_link} Tasks to produce #{task_type_argument_hash[task_prototype_name][:output]}."
      new_task_ids.push t.id
    end
  end
  return {
    new_task_ids: new_task_ids,
    notifs: notifs
  }
end

def sequencing_verification_task_processing t
  new_task_ids = []
  status_to_process = ["sequence correct", "sequence correct but keep plate", "sequence correct but redundant", "sequence wrong"]
  if status_to_process.include? t.status
    discard_item_ids = [] # list of items to discard
    stock_item_ids = [] # list of items to glycerol stock
    plasmid_stock_id = t.simple_spec[:plasmid_stock_ids][0]
    plasmid_stock = find(:item, id: plasmid_stock_id)[0]
    overnight_id = t.simple_spec[:overnight_ids][0]
    overnight = find(:item, id: overnight_id)[0]
    plate, gibson_reaction_results = nil, []
    if overnight
      plate_id = overnight.datum[:from]
      plate = find(:item, id: plate_id)[0]
      gibson_reaction_results = overnight.sample.in("Gibson Reaction Result")
    end
    case t.status
    when "sequence correct"
      discard_item_ids.concat gibson_reaction_results.collect { |g| g.id }
      discard_item_ids.push plate.id if plate
      stock_item_ids.push overnight.id if overnight
    when "sequence correct but keep plate"
      stock_item_ids.push overnight.id if overnight
    when "sequence correct but redundant", "sequence wrong"
      discard_item_ids.push plasmid_stock.id if plasmid_stock
      discard_item_ids.push overnight.id if overnight
    end
    # create new tasks
    new_discard_tasks = create_new_tasks(discard_item_ids, task_name: "Discard Item", user_id: t.user.id)
    new_stock_tasks = create_new_tasks(stock_item_ids, task_name: "Glycerol Stock", user_id: t.user.id)
    notifs = new_discard_tasks[:notifs] + new_stock_tasks[:notifs]
    new_task_ids.concat new_discard_tasks[:new_task_ids] + new_stock_tasks[:new_task_ids]
    t.status = "done"
    t.save
  end
  return {
    new_task_ids: new_task_ids,
    notifs: notifs
  }
end
