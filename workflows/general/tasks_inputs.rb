needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  # a function that returns a table of task information
  def task_info_table task_ids

    task_ids.compact!

    if task_ids.length == 0
      return []
    end

    tab = [[ "Task ids", "Task type", "Task name", "Task owner"]]

    task_ids.each do |tid|
      task = find(:task, id: tid)[0]
      tab.push [ tid, task.task_prototype.name, task.name, task.user.name ]
    end

    return tab

  end

  # a function that find primers that need to be ordered for a list of fragment ids, return a list of primer ids that need to be ordered.
  def missing_primer fids

    primers = []
    fids.each do |fid|
      fragment = find(:sample, id: fid )[0]
      fwd = fragment.properties["Forward Primer"]
      rev = fragment.properties["Reverse Primer"]
      primers.push fwd.id if fwd && (fwd.in("Primer Aliquot").length == 0) && (fwd.in("Primer Stock").length == 0)
      primers.push rev.id if rev && (rev.in("Primer Aliquot").length == 0) && (rev.in("Primer Stock").length == 0)
    end

    return primers.uniq

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

  # a simple function to diplay user input for how many tasks to choose from the queue and present user
  # timing info vs size, return numer of tasks user chooses.
  def task_size_select task_name, sizes, tetra_tab = nil

    if sizes.length > 0
      limit_input = show {
        title "How many #{task_name} to run?"
        note "There is a total of #{sizes[-1]} #{task_name} in the queue. How many do you want to run?"
        select sizes, var: "limit", label: "Enter the number of #{task_name} you want to run", default: sizes[-1]
        if tetra_tab
          note "Tetra predictions for estimated job duration in minutes."
          table tetra_tab
        end
      }
      return limit_input[:limit].to_i
    else
      return 0
    end

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

  # return errors that prevents fragment to be valid to build
  # assert specific properties by supplying an array in assert_property
  def fragment_check fids, p={}
    params = ({ assert_property: ["Forward Primer","Reverse Primer","Template","Length"], check_type: "sample_properties" }).merge p
    errors = []
    fids = [fids] if fids.is_a? Numeric
    fids.each do |fid|
      fragment = find(:sample, id: fid)[0]
      if params[:check_type] == "sample_properties"
        params[:assert_property].each do |field|
          if fragment.properties[field]
            case field
            when "Forward Primer", "Reverse Primer"
              pid = fragment.properties[field].id
              errors.concat primer_check([pid], check_type: "inventory_exist")
            when "Template"
              template_stock_hash = {
                "Plasmid" => ["1 ng/µL Plasmid Stock", "Plasmid Stock", "Gibson Reaction Result"],
                "Fragment" => ["1 ng/µL Fragment Stock", "Fragment Stock" ],
                "E coli strain" => ["E coli Lysate", "Genome Prep"],
                "Yeast Strain" => ["Lysate", "Yeast cDNA"]
              }
              template_stocks = []
              template = fragment.properties[field]
              template_stock_hash[template.sample_type.name].each do |container|
                template_stocks.push template.in(container)[0]
              end
              template_stocks.compact!
              errors.push(template_stock_hash[template.sample_type.name].join(" or ").to_s + " is required for fragment #{fid} template") if template_stocks.empty?
            when "Length"
              length = fragment.properties[field] || 0
              errors.push unless length > 0
            end
          else
            errors.push "#{field} is required for fragment #{fid}"
          end
        end #params[:assert_property]
      elsif params[:check_type] == "inventory_exist"
        errors.push "Fragment #{fid} requires a Fragment Stock" if fragment.in("Fragment Stock").empty?
      end # if check_type == "sample_properties"
    end
    return errors
  end

  # check_type: sample_properties or inventory_exist
  # sample_properties will check the desired sample_property of this primer
  # inventory_exist will check if primer aliquot or primer stock exist
  def primer_check pids, p={}
    params = ({ check_type: "sample_properties" }).merge p
    errors = []
    pids.each do |pid|
      primer = find(:sample, id: pid)[0]
      if params[:check_type] == "sample_properties"
        overhang = primer.properties["Overhang Sequence"] || ""
        anneal = primer.properties["Anneal Sequence"] || ""
        tanneal = primer.properties["T Anneal"] || 0
        errors.push "Need Overhang or Anneal Sequence Info" if (overhang + anneal).empty?
        errors.push "Need T Anneal info" if tanneal < 40
      elsif params[:check_type] == "inventory_exist"
        if primer.in("Primer Aliquot").empty? && primer.in("Primer Stock").empty?
          errors.push "Primer #{pid} requires a Primer Aliquot or Primer Stock"
        end
      end
    end
    return errors
  end

  # returns errors of inventory_check and possible needs for submitting new tasks
  def inventory_check ids, p={}
    params = ({ sample_type: "", inventory_types: "" }).merge p
    ids = [ids] if ids.is_a? Numeric
    need_to_make_ids = [] # put the list of sample ids that need inventory_type to be made
    sample_type = params[:sample_type]
    inventory_types = params[:inventory_types]
    inventory_types = [inventory_types] if inventory_types.is_a? String
    errors = []
    ids.each do |id|
      sample = find(:sample, id: id)[0]
      warning = []
      inventory_types.each do |inventory_type|
        if sample.in(inventory_type).empty?
          warning.push "#{sample_type} #{id} does not have a #{inventory_type}."
        end
      end
      if warning.length == inventory_types.length
        errors.push "#{sample_type} #{id} requires a #{inventory_types.join(" or ")}."
        need_to_make_ids.push id
      end
    end
    return errors, need_to_make_ids
  end

  def sample_check ids, p={}
    params = ({ sample_type: "", assert_property: []}).merge p
    ids = [ids] if ids.is_a? Numeric
    sample_type = params[:sample_type]
    assert_properties = params[:assert_property]
    assert_properties = [assert_properties] if assert_properties.is_a? String
    if sample_type.empty? || assert_properties.empty?
      return nil
    end
    errors = []
    ids_to_make = [] # ids that require inventory to be made through other tasks
    ids.each do |id|
      sample = find(:sample, id: id)[0]
      assert_properties.each do |field|
        if sample.properties[field]
          property = sample.properties[field]
          case field
          when "Forward Primer", "Reverse Primer"
            pid = property.id
            error, id_to_make = inventory_check pid, sample_type: "Primer", inventory_types: ["Primer Aliquot", "Primer Stock"]
            errors.concat error
            ids_to_make.concat id_to_make
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
            errors.push(template_stock_hash[template.sample_type.name].join(" or ").to_s + " is required for #{sample_type} #{id} Template") if template_stocks.empty?
          when "Length"
            errors.push "Length greater than 0 is required for #{sample_type} #{id}" unless property > 0
          when "Bacterial Marker", "Yeast Marker"
            errors.push "Nonempty #{field} is required for #{sample_type} #{id}" unless property.length > 0
          end # case
        else
          errors.push "#{field} is required for #{sample_type} #{id}"
        end # if sample.properties[field]
      end # assert_properties.each
    end # ids.each
    return errors, ids_to_make
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
      t.spec.each do |argument, ids|
        argument = argument.to_s
        variable_name = argument.split(' ')[0]
        argument.slice!(argument.split(' ')[0])
        argument.slice!(0) # remove white space in the beginning
        inventory_types = argument.split('|')
        ids = [ids] unless ids.is_a? Array
        ids.flatten!
        ids.uniq!
        # processing sample type or inventory type check
        if inventory_types.any?
          if object_type_names & inventory_types == inventory_types
            item_or_sample = :item
          elsif sample_type_names & inventory_types == inventory_types
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
              errors.concat primer_check(ids, check_type: "sample_properties")
            else  # for Sequencing, Plasmid Verification
              error, ids_to_make = inventory_check ids, sample_type: "Primer", inventory_types: ["Primer Aliquot", "Primer Stock"]
              errors.concat error
              errors.push "Primer Order tasks for #{ids_to_make.join(", ")} will be submitted." if ids_to_make.any?
            end
          when "fragments"
            if params[:name] == "Fragment Construction"
              error, ids_to_make = sample_check(ids, sample_type: "Fragment", assert_property: ["Forward Primer","Reverse Primer","Template","Length"])
              errors.concat error
              errors.push "Primer Order tasks for #{ids_to_make.join(", ")} will be submitted." if ids_to_make.any?
            elsif params[:name] == "Gibson Assembly"
              error, ids_to_make = inventory_check(ids, sample_type: "Fragment", inventory_types: "Fragment Stock")
              errors.concat error
              if ids_to_make.any?
                new_task_ids.concat create_new_tasks(ids_to_make, task_name: "Fragment Construction")
              end
              errors.concat sample_check(ids, sample_type: "Fragment", assert_property: "Length")[0]
            end
          when "num_colonies"
            ids.each do |id|
              errors.push "A number between 0,10 is required for num_colonies" unless id.between?(0, 10)
            end
          when "plasmid"
            errors.concat sample_check(ids, sample_type: "Plasmid", assert_property: "Bacterial Marker")[0]
          end # case
        end # errors.empty?
      end # t.spec.each
      if errors.any?
        errors.each { |error| t.notify error, job_id: jid }
        set_task_status(t, "waiting") unless t.status == "waiting"
      else
        set_task_status(t, "ready") unless t.status == "ready"
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

  def create_new_tasks ids, p={}
    params = ({ task_name: "" }).merge p
    new_task_ids = []
    case params[:task_name]
    when "Fragment Construction"
      ids.each do |id|
        fragment = find(:sample, id: id)[0]
        tp = TaskPrototype.where("name = 'Fragment Construction'")[0]
        task = find(:task, name: "#{fragment.name}")[0]
        if task
          if task.status == "done"
            set_task_status(task, "waiting")
            task.notify "Automatically changed status to waiting to make more fragments", job_id: jid
            new_task_ids.push task.id
          elsif ["failed","canceled"].include? task.status
            task.notify "Fragment Construction task for #{id} was failed or canceled. You need to manually switch the status if you still want the fragment to be made.", job_id: jid
          else
            task.notify "Fragment Construction task for #{id} is already in the workflow.", job_id: jid
          end
        else
          t = Task.new(name: "#{fragment.name}", specification: { "fragments Fragment" => [ id ]}.to_json, task_prototype_id: tp.id, status: "waiting", user_id: fragment.user.id)
          t.save
          t.notify "Automatically created in the workflow.", job_id: jid
          new_task_ids.push t.id
        end
      end
    end #when
    return new_task_ids
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
    # io_hash = { debug_mode: "No", item_ids: [], overnight_ids: [], plate_ids: [], task_name: "", fragment_ids: [], plasmid_ids: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # # Add automatically creating new tasks
    # new_task_ids = auto_create_new_tasks task_name: io_hash[:task_name], group: io_hash[:group]

    # process task_status
    tasks = task_status name: io_hash[:task_name], group: io_hash[:group]
    io_hash[:task_ids] = tasks[:ready_ids]
    sizes = [] # a variable to store possible run sizes for all tasks

    wating_tab = task_info_table tasks[:waiting_ids]
    ready_tab = task_info_table tasks[:ready_ids]

    show {
      title "Task status"
      note "For #{io_hash[:task_name]} tasks that belong to #{io_hash[:group]}:"
      if tasks[:waiting_ids].length > 0
        note "Waiting tasks:"
        note "If your desired to run task still stays in waiting, abort this protocol, it will be automatically rescheduled. Fix the task input problem and rerun this protocol."
        table wating_tab
      else
        note "No task is wating"
      end
      if tasks[:ready_ids].length > 0
        note "Ready tasks:"
        table ready_tab
      else
        note "No task is ready"
      end
    }

    # show the users about newly created tasks
    new_task_ids = tasks[:new_task_ids]
    if new_task_ids.any?
      new_task_table = task_info_table(new_task_ids)
      show {
        title "New tasks"
        note "The following tasks are automatically created or status adjusted."
        table new_task_table
      }
    end

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

      # Find sequencing verification correct tasks that belongs to io_hash[:group]
      seq_verifi_tasks = find(:task, { task_prototype: { name: "Sequencing Verification" } })
      correct_seq_verifi_tasks = seq_verifi_tasks.select { |t| t.status == "sequence correct" || t.status == "sequence correct but keep plate" }
      correct_seq_verifi_task_ids = correct_seq_verifi_tasks.collect { |t| t.id }
      correct_seq_verifi_task_ids = task_group_filter correct_seq_verifi_task_ids, io_hash[:group]

      tp = TaskPrototype.where("name = 'Discard Item'")[0]

      new_discard_item_task_ids = []

      #Add sequence correct items to glycerol stock
      correct_seq_verifi_task_ids.each do |tid|
        io_hash[:task_ids].push tid
        task = find(:task, id: tid)[0]
        io_hash[:overnight_ids].concat task.simple_spec[:overnight_ids]

        if task.status == "sequence correct"
          # make new discard item tasks for corresponding plate
          discard_item_ids = [] # empty list to store item ids to discard
          overnight = find(:item, id: task.simple_spec[:overnight_ids][0])[0]
          # find plate_id to discard
          plate_id = overnight.datum[:from]
          plate = find(:item, id: plate_id)[0]
          if plate
            discard_item_ids.push plate_id
          end
          # find gibson reaction result id to discard
          gibson_reaction_results = overnight.sample.in("Gibson Reaction Result")
          if gibson_reaction_results.length > 0
            discard_item_ids.concat gibson_reaction_results.collect { |g| g.id }
          end
          if discard_item_ids.length > 0
            t = Task.new(name: "#{plate.sample.name}_gibson_results_and_plate", specification: { "item_ids Yeast Plate" => discard_item_ids }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: (plate || gibson_reaction_results[0]).sample.user.id)
            t.save
            t.notify "Automatically created from Sequencing Verification.", job_id: jid
            new_discard_item_task_ids.push t.id
          end
        end
      end

      if new_discard_item_task_ids.length > 0
        new_discard_item_task_table = task_info_table(new_discard_item_task_ids)
        show {
          title "New Dicard Items tasks"
          note "The following dicard items tasks are automatically generated for gibson results and plate that has correct sequenced plasmid stocks."
          table new_discard_item_task_table
        }
      end

      io_hash[:size] = io_hash[:overnight_ids].length + io_hash[:item_ids].length

    when "Discard Item"
      io_hash = { item_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:item_ids].concat task.simple_spec[:item_ids]
      end

      # Find sequencing verification wrong tasks that belongs to io_hash[:group]
      seq_verifi_tasks = find(:task, { task_prototype: { name: "Sequencing Verification" } })
      wrong_seq_verifi_tasks = seq_verifi_tasks.select { |t| t.status == "sequence wrong" }
      wrong_seq_verifi_task_ids = wrong_seq_verifi_tasks.collect { |t| t.id }
      wrong_seq_verifi_task_ids = task_group_filter wrong_seq_verifi_task_ids, io_hash[:group]

      # Add sequence wrong items to discard item
      wrong_seq_verifi_task_ids.each do |tid|
        io_hash[:task_ids].push tid
        task = find(:task, id: tid)[0]
        io_hash[:item_ids].concat task.simple_spec[:plasmid_stock_ids]
        io_hash[:item_ids].concat task.simple_spec[:overnight_ids]
      end
      io_hash[:size] = io_hash[:item_ids].length

    when "Streak Plate"
      io_hash = { item_ids: [], plate_ids:[] }.merge io_hash
      yeast_competent_cells = task_status name: "Yeast Competent Cell", group: io_hash[:group]
      need_to_streak_glycerol_stocks = []
      new_streak_plate_task_ids = []
      if yeast_competent_cells[:yeast_strains]
        if yeast_competent_cells[:yeast_strains][:ready_to_streak].length > 0
          yeast_competent_cells[:yeast_strains][:ready_to_streak].each do |yid|
            y = find(:sample, id: yid)[0]
            y_stocks = y.in("Yeast Glycerol Stock")
            need_to_streak_glycerol_stocks.push y_stocks[0].id
          end

          need_to_streak_glycerol_stocks.each do |id|
            y = find(:item, id: id)[0]
            tp = TaskPrototype.where("name = 'Streak Plate'")[0]
            task = find(:task, name: "#{y.sample.name}_streak_plate")[0]
            # check if task already exists, if so, reset its status to waiting, if not, create new tasks.
            if task
              if task.status == "imaged and stored in fridge"
                set_task_status(task,"waiting")
                task.notify "Automatically changed status to waiting to make more competent cells as needed from Yeast Transformation.", job_id: jid
                task.save
              end
            else
              t = Task.new(name: "#{y.sample.name}_streak_plate", specification: { "item_ids Yeast Glycerol Stock" => [ id ]}.to_json, task_prototype_id: tp.id, status: "waiting", user_id: y.sample.user.id)
              t.save
              t.notify "Automatically created from Yeast Competent Cell.", job_id: jid
              new_streak_plate_task_ids.push t.id
            end
          end
        end

        if new_streak_plate_task_ids.length > 0
          new_streak_plate_tab = task_info_table(new_streak_plate_task_ids)
          show {
            title "New Streak Plate tasks"
            note "The following Streak Plate tasks are automatically generated for yeast strains that need to streak plate in Yeast Competent Cell tasks."
            table new_streak_plate_tab
          }
        end
      end

      streak_plate_tasks = task_status name: "Streak Plate", group: io_hash[:group]
      io_hash[:task_ids] = streak_plate_tasks[:ready_ids]
      io_hash[:yeast_glycerol_stock_ids] = []
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.simple_spec[:item_ids].each do |id|
          if find(:item, id: id)[0].object_type.name == "Yeast Glycerol Stock"
            io_hash[:yeast_glycerol_stock_ids].push id
          elsif ["Yeast Plate", "Plate"].include? find(:item, id: id)[0].object_type.name
            io_hash[:plate_ids].concat task.simple_spec[:item_ids]
          else
            io_hash[:item_ids].concat task.simple_spec[:item_ids]
          end
        end
      end
      io_hash[:size] = io_hash[:yeast_glycerol_stock_ids].length + io_hash[:plate_ids].length

    when "Gibson Assembly"
      io_hash = { fragment_ids: [], plasmid_ids: [] }.merge io_hash
      sizes = (1..io_hash[:task_ids].length).to_a
      tetra_tab = [[ "size", "gibson"]]
      sizes.each do |size|
        tetra_tab.push [size, time_prediction(size, "gibson")]
      end
      limit = task_size_select(io_hash[:task_name], sizes, tetra_tab)
      io_hash[:task_ids] = io_hash[:task_ids].take(limit)
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:fragment_ids].push task.simple_spec[:fragments]
        io_hash[:plasmid_ids].push task.simple_spec[:plasmid]
      end
      io_hash[:size] = io_hash[:plasmid_ids].length

    when "Fragment Construction"
      io_hash = { fragment_ids: [] }.merge io_hash
      # # pull out fragments that need to be made from Gibson Assembly tasks
      #
      #
      # fs = task_status name: "Fragment Construction", group: io_hash[:group], notification: "on"
      #
      # need_to_order_primer_ids = missing_primer(fs[:fragments][:not_ready_to_build].uniq)
      # new_primer_order_ids = []
      #
      # need_to_order_primer_ids.each do |id|
      #   primer = find(:sample, id: id)[0]
      #   tp = TaskPrototype.where("name = 'Primer Order'")[0]
      #   t = Task.new(name: "#{primer.name}", specification: { "primer_ids Primer" => [ id ]}.to_json, task_prototype_id: tp.id, status: "waiting", user_id: primer.user.id)
      #   t.save
      #   t.notify "Automatically created from Fragment Construction.", job_id: jid
      #   new_primer_order_ids.push t.id
      # end
      #
      # new_primer_order_ids.compact!
      #
      # if new_primer_order_ids.length > 0
      #   new_primer_order_tab = task_info_table(new_primer_order_ids)
      #   show {
      #     title "New Primer Order tasks"
      #     note "The following Primer Order tasks are automatically generated for primers that need to be ordered from Fragment Constructions."
      #     table new_primer_order_tab
      #   }
      # end
      #
      # # pull out fragments from Fragment Construction tasks and cut off based on limits for non tech groups
      # io_hash[:task_ids] = fs[:ready_ids]
      fragment_ids = []
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        fragment_ids.concat task.simple_spec[:fragments]
        fragment_ids.uniq!
        sizes.push fragment_ids.length
      end

      tetra_all_tab = [[ "size", "PCR","run_gel","cut_gel","purify_gel" ]]
      sizes.each do |size|
        job_times = []
        ["PCR","run_gel","cut_gel","purify_gel"].each do |protocol_name|
          job_times.push time_prediction(size, protocol_name)
        end
        tetra_all_tab.push([size].concat job_times)
      end
      size_limit = task_size_select(io_hash[:task_name], sizes, tetra_all_tab)

      limit_idx = 0
      io_hash[:task_ids].each_with_index do |tid,idx|
        task = find(:task, id: tid)[0]
        io_hash[:fragment_ids].concat task.simple_spec[:fragments]
        io_hash[:fragment_ids].uniq!
        if io_hash[:fragment_ids].length >= size_limit
          limit_idx = idx + 1
          break
        end
      end
      io_hash[:task_ids] = io_hash[:task_ids].take(limit_idx)
      io_hash[:size] = io_hash[:fragment_ids].length

      # adding Tetra (time estimation tool for Aquarium) display
      tetra_tab = [[ "Protocol Name", "Esitmated Time (min)"]]

      ["PCR","run_gel","cut_gel","purify_gel"].each do |protocol_name|
        tetra_tab.push [protocol_name, time_prediction(io_hash[:size], protocol_name)]
      end

      show {
        title "Tetra time predictions"
        note "There is #{io_hash[:size]} #{io_hash[:task_name]} to do. Tetra prediction for
        each job duration in minutes is following."
        table tetra_tab
      }

    when "Plasmid Verification"
      io_hash = { num_colonies: [], plate_ids: [], primer_ids: [], initials: [], glycerol_stock_ids: [], size: 0 }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task_size = task.simple_spec[:num_colonies].inject { |sum, n| sum + n }
        sizes.push( task_size + (sizes[-1] || 0) )
      end
      size_limit = task_size_select(io_hash[:task_name], sizes)

      current_size, limit_idx = 0, 0
      io_hash[:task_ids].each_with_index do |tid, idx_outer|
        task = find(:task, id: tid)[0]
        task.simple_spec[:plate_ids].each_with_index do |pid, idx|
          if task.simple_spec[:primer_ids][idx] != [0]
            io_hash[:plate_ids].push pid
            io_hash[:num_colonies].push task.simple_spec[:num_colonies][idx]
            io_hash[:primer_ids].push task.simple_spec[:primer_ids][idx]
            current_size = current_size + task.simple_spec[:num_colonies][idx]
          else
            io_hash[:glycerol_stock_ids].push pid
            current_size = current_size + 1
          end
        end
        if current_size >= size_limit
          limit_idx = idx_outer + 1
          break
        end
      end

      io_hash[:task_ids] = io_hash[:task_ids].take(limit_idx)
      io_hash[:size] = io_hash[:num_colonies].inject { |sum, n| sum + n } || 0 + io_hash[:glycerol_stock_ids].length

    when "Yeast Transformation"
      io_hash = { yeast_transformed_strain_ids: [], plasmid_stock_ids: [], yeast_parent_strain_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        sizes.push(task.simple_spec[:yeast_transformed_strain_ids].length + (sizes[-1] || 0))
      end
      size_limit = task_size_select(io_hash[:task_name], sizes)
      limit_idx = sizes.index(size_limit) || 0
      io_hash[:task_ids] = io_hash[:task_ids].take(limit_idx + 1)
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
        task_size = task.simple_spec[:num_colonies].inject { |sum, n| sum + n }
        sizes.push( task_size + (sizes[-1] || 0) )
      end
      size_limit = task_size_select(io_hash[:task_name], sizes)
      limit_idx = sizes.index(size_limit) || 0
      io_hash[:task_ids] = io_hash[:task_ids].take(limit_idx + 1)
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

    when "Yeast Competent Cell"
      yeast_transformations = task_status name: "Yeast Transformation", group: io_hash[:group]
      if yeast_transformations[:yeast_strains] && yeast_transformations[:yeast_strains][:not_ready_to_build].length > 0

        need_to_make_competent_yeast_ids = []
        yeast_transformations[:yeast_strains][:not_ready_to_build].each do |yid|
          y = find(:sample, id: yid)[0]
          if y
            if y.properties["Parent"] && y.properties["Parent"].in("Yeast Competent Aliquot").length == 0 && y.properties["Parent"].in("Yeast Competent Cell").length == 0
              need_to_make_competent_yeast_ids.push y.properties["Parent"].id
            end
          end
        end

        new_yeast_competent_cell_task_ids = []
        need_to_make_competent_yeast_ids.each do |id|
          y = find(:sample, id: id)[0]
          tp = TaskPrototype.where("name = 'Yeast Competent Cell'")[0]
          task = find(:task, name: "#{y.name}_comp_cell")[0]
          # check if task already exists, if so, reset its status to waiting, if not, create new tasks.
          if task
            if task.status == "done"
              set_task_status(task,"waiting")
              task.notify "Automatically changed status to waiting to make more competent cells as needed from Yeast Transformation.", job_id: jid
              task.save
            end
          else
            t = Task.new(name: "#{y.name}_comp_cell", specification: { "yeast_strain_ids Yeast Strain" => [ id ]}.to_json, task_prototype_id: tp.id, status: "waiting", user_id: y.user.id)
            t.save
            t.notify "Automatically created from Yeast Transformation.", job_id: jid
            new_yeast_competent_cell_task_ids.push t.id
          end
        end

        if new_yeast_competent_cell_task_ids.length > 0
          new_yeast_competent_cells_tab = task_info_table(new_yeast_competent_cell_task_ids)
          show {
            title "New Yeast Competent Cell tasks"
            note "The following Yeast Competent Cell tasks are automatically generated for yeast strains that need to make competent cells in Yeast Transformation tasks."
            table new_yeast_competent_cells_tab
          }
        end

      end

      yeast_competent_cell_tasks = task_status name: "Yeast Competent Cell", group: io_hash[:group]
      io_hash[:task_ids] = yeast_competent_cell_tasks[:ready_ids]
      io_hash = { yeast_strain_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:yeast_strain_ids].concat task.simple_spec[:yeast_strain_ids]
      end
      io_hash[:yeast_strain_ids].uniq!
      io_hash[:size] = io_hash[:yeast_strain_ids].length
      io_hash[:volume] = 2

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
        note "The following tasks inputs has been processed and returned as outputs. There are #{io_hash[:size]} #{io_hash[:task_name].pluralize(io_hash[:size])} to do."
        table tasks_tab
      else
        note "No task's input is returned as outputs"
      end
    }

    return { io_hash: io_hash }
  end

end
