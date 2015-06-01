needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def task_status_debug p={}

    # This function is used to debug task_status function in cloning.rb

    params = ({ group: false, name: "" }).merge p
    raise "Supply a Task name for the task_status function as tasks_status name: task_name" if params[:name].length == 0
    tasks_all = find(:task,{task_prototype: { name: params[:name] }})
    tasks = []
    # filter out tasks based on group input
    if params[:group] && !params[:group].empty?
      user_group = params[:group] == "technicians"? "cloning": params[:group]
      group_info = Group.find_by_name(user_group)
      tasks_all.each do |t|
        tasks.push t if t.user.member? group_info.id
      end
    else
      tasks = tasks_all
    end
    waiting = tasks.select { |t| t.status == "waiting" }
    ready = tasks.select { |t| t.status == "ready" }

    # cycling through waiting and ready to make sure tasks inputs are valid

    (waiting + ready).each do |t|

      case params[:name]

      when "Yeast Strain QC"
        length_check = t.simple_spec[:yeast_plate_ids].length == t.simple_spec[:num_colonies].length
        t.notify "yeast_plate_ids need to have the same array length with num_colonies.", job_id: jid if !length_check
        t[:yeast_plate_ids] = { ready_to_QC: [], not_ready_to_QC: [] }
        t.simple_spec[:yeast_plate_ids].each_with_index do |yid, idx|
          primer1 = find(:item, id: yid)[0].sample.properties["QC Primer1"].in("Primer Aliquot")[0]
          primer2 = find(:item, id: yid)[0].sample.properties["QC Primer2"].in("Primer Aliquot")[0]
          if primer1 && primer2 && (t.simple_spec[:num_colonies][idx] || 0).between?(0, 10)
            t[:yeast_plate_ids][:ready_to_QC].push yid
          else
            t[:yeast_plate_ids][:not_ready_to_QC].push yid
            t.notify "QC Primer 1 for yeast plate #{yid} does not have any primer aliquot.", job_id: jid if !primer1
            t.notify "QC Primer 2 for yeast plate #{yid} does not have any primer aliquot.", job_id: jid if !primer2
            t.notify "num_colonies for yeast plate #{yid} need to be a number between 0,10", job_id: jid if !(t.simple_spec[:num_colonies][idx] || 0).between?(0, 10)
          end
        end

        ready_conditions = length_check && t[:yeast_plate_ids][:ready_to_QC].length == t.simple_spec[:yeast_plate_ids].length

      end

      if ready_conditions
        set_task_status(t, "ready")
        t.save
      else
        set_task_status(t, "waiting")
        t.save
      end

    end

    task_status_hash = {
      waiting_ids: (tasks.select { |t| t.status == "waiting" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id}
    }

    task_status_hash[:fragments] = ((waiting + ready).collect { |t| t[:fragments] }).inject { |all,part| all.each { |k,v| all[k].concat part[k] } } if ["Gibson Assembly", "Fragment Construction"].include? params[:name]

    return task_status_hash

  end

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

  def arguments
    {
      io_hash: {},
      debug_mode: "Yes",
      task_name: "Gibson Assembly",
      group: "technicians"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", item_ids: [], overnight_ids: [], plate_ids: [], task_name: "", fragment_ids: [], plasmid_ids: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    tasks = task_status name: io_hash[:task_name], group: io_hash[:group]
    io_hash[:task_ids] = tasks[:ready_ids]

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

    case io_hash[:task_name]

    when "Glycerol Stock"
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
          plate_id = find(:item, id: task.simple_spec[:overnight_ids][0])[0].datum[:from]
          plate = find(:item, id: plate_id)[0]
          gibson_reaction_results = plate.sample.in("Gibson Reaction Result")
          gibson_reaction_result_ids = gibson_reaction_results.collect { |g| g.id }
          discard_item_ids = gibson_reaction_result_ids.push plate_id
          t = Task.new(name: "#{plate.sample.name}_gibson_results_and_plate", specification: { "item_ids Yeast Plate" => discard_item_ids }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: plate.sample.user.id)
          t.save
          t.notify "Automatically created from Sequencing Verification.", job_id: jid
          new_discard_item_task_ids.push t.id
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
      yeast_competent_cells = task_status name: "Yeast Competent Cell", group: io_hash[:group]
      need_to_streak_glycerol_stocks = []
      if yeast_competent_cells[:yeast_strains][:ready_to_streak].length > 0
        yeast_competent_cells[:yeast_strains][:ready_to_streak].each do |yid|
          y = find(:sample, id: yid)[0]
          y_stocks = y.in("Yeast Glycerol Stock")
          need_to_streak_glycerol_stocks.push y_stocks[0].id
        end

        new_streak_plate_task_ids = []
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
      # if tasks[:fragments]
      #   waiting_ids = tasks[:waiting_ids]
      #   users = waiting_ids.collect { |tid| find(:task, id: tid)[0].user.name }
      #   fragment_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:fragments] }
      #   ready_to_use_fragment_ids = tasks[:fragments][:ready_to_use].uniq
      #   not_ready_to_use_fragment_ids = tasks[:fragments][:not_ready_to_use].uniq
      #   ready_to_build_fragment_ids = tasks[:fragments][:ready_to_build].uniq
      #   not_ready_to_build_fragment_ids = tasks[:fragments][:not_ready_to_build].uniq
      #   plasmid_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:plasmid] }
      #   plasmids = plasmid_ids.collect { |pid| find(:sample, id: pid)[0]}
      #   tasks_tab = [[ "Not ready tasks", "Tasks owner", "Plasmid", "Fragments", "Ready to build", "Not ready to build", "Length info missing" ]]
      #   waiting_ids.each_with_index do |tid,idx|
      #     tasks_tab.push [ tid, users[idx], "#{plasmids[idx]}", fragment_ids[idx].to_s, (fragment_ids[idx]&ready_to_build_fragment_ids).to_s, (fragment_ids[idx]&not_ready_to_build_fragment_ids).to_s,(fragment_ids[idx]&not_ready_to_use_fragment_ids).to_s ]
      #   end
      #   show {
      #     title "Gibson Assemby Status"
      #     note "Ready to build means recipes and ingredients for building this fragments are complete."
      #     note "Not ready to build means some information or stocks are missing."
      #     note "Length info missing means the fragment are already in stock but does not have length information needed for Gibson assembly."
      #     table tasks_tab
      #   }
      # end
      # if io_hash[:group] != "technicians"
      #   io_hash[:task_ids] = io_hash[:task_ids].take(12)
      # end
      # adding Tetra (time estimation tool for Aquarium) display
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

      # pull out fragments that need to be made from Gibson Assembly tasks
      gibson_tasks = task_status name: "Gibson Assembly", group: io_hash[:group]
      if gibson_tasks[:fragments][:need_to_build].length > 0

        need_to_make_fragment_ids = gibson_tasks[:fragments][:need_to_build].uniq
        new_fragment_construction_ids = []

        need_to_make_fragment_ids.each do |id|
          fragment = find(:sample, id: id)[0]
          tp = TaskPrototype.where("name = 'Fragment Construction'")[0]
          task = find(:task, name: "#{fragment.name}")[0]
          if task
            if task.status == "done"
              set_task_status(task, "waiting")
              task.notify "Automatically changed status to waiting to make more fragments", job_id: jid
            end
          else
            t = Task.new(name: "#{fragment.name}", specification: { "fragments Fragment" => [ id ]}.to_json, task_prototype_id: tp.id, status: "waiting", user_id: fragment.user.id)
            t.save
            t.notify "Automatically created from Gibson Assembly.", job_id: jid
            new_fragment_construction_ids.push t.id
          end
        end

        new_fragment_construction_ids.compact!

        if new_fragment_construction_ids.length > 0
          new_fragment_construction_tasks_tab = task_info_table(new_fragment_construction_ids)
          show {
            title "New fragment Construction tasks"
            note "The following fragment Construction tasks are automatically generated for fragments that need to be built in Gibson Assemblies."
            table new_fragment_construction_tasks_tab
          }
        end

      end

      fs = task_status name: "Fragment Construction", group: io_hash[:group], notification: "on"
      # if fs[:fragments] && fs[:fragments][:not_ready_to_build].length > 0
      #   waiting_ids = fs[:waiting_ids]
      #   users = waiting_ids.collect { |tid| find(:task, id: tid)[0].user.name }
      #   fragment_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:fragments] }
      #   ready_to_build_fragment_ids = fs[:fragments][:ready_to_build].uniq
      #   not_ready_to_build_fragment_ids = fs[:fragments][:not_ready_to_build].uniq
      #   fs_tab = [[ "Not ready tasks", "Tasks owner", "Fragments", "Ready to build", "Not ready to build" ]]
      #   waiting_ids.each_with_index do |tid,idx|
      #     fs_tab.push [ tid, users[idx], fragment_ids[idx].to_s, (fragment_ids[idx]&ready_to_build_fragment_ids).to_s, (fragment_ids[idx]&not_ready_to_build_fragment_ids).to_s ]
      #   end
      #   show {
      #     title "Fragment Construction Status"
      #     note "Ready to build means recipes and ingredients for building this fragments are complete. Not ready to build means some information or stocks are missing."
      #     table fs_tab
      #   }
      # end

      # automatically submit primer order tasks if both primer stock and primer aliquot are missing for not_ready_to_build fragments.
      need_to_order_primer_ids = missing_primer(fs[:fragments][:not_ready_to_build].uniq)
      new_primer_order_ids = []

      need_to_order_primer_ids.each do |id|
        primer = find(:sample, id: id)[0]
        tp = TaskPrototype.where("name = 'Primer Order'")[0]
        t = Task.new(name: "#{primer.name}", specification: { "primer_ids Primer" => [ id ]}.to_json, task_prototype_id: tp.id, status: "waiting", user_id: primer.user.id)
        t.save
        t.notify "Automatically created from Fragment Construction.", job_id: jid
        new_primer_order_ids.push t.id
      end

      new_primer_order_ids.compact!

      if new_primer_order_ids.length > 0
        new_primer_order_tab = task_info_table(new_primer_order_ids)
        show {
          title "New Primer Order tasks"
          note "The following Primer Order tasks are automatically generated for primers that need to be ordered from Fragment Constructions."
          table new_primer_order_tab
        }
      end

      # pull out fragments from Fragment Construction tasks and cut off based on limits for non tech groups
      io_hash[:task_ids] = fs[:ready_ids]
      sizes, fragment_ids = [], []
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
      io_hash = { num_colonies: [], primer_ids: [], initials: [], glycerol_stock_ids: [], size: 0 }.merge io_hash
      sizes = []
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
