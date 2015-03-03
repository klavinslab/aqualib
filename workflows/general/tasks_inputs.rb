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
        length_check = t.simple_spec[:yeast_plate_ids].length == t.simple_spec[:num_colonies]
        t[:yeast_plate_ids] = { ready_to_QC: [], not_ready_to_QC: [] }
        sample_check = true
        t.simple_spec[:yeast_plate_ids].each_with_index do |yid, idx|
          primer1 = find(:item, id: yid)[0].sample.properties["QC Primer1"].in("Primer Aliquot")[0]
          primer2 = find(:item, id: yid)[0].sample.properties["QC Primer2"].in("Primer Aliquot")[0]
          if primer1 && primer2 && t.simple_spec[:num_colonies][idx] > 0
            t[:yeast_plate_ids][:ready_to_QC].push yid
          else
            t[:yeast_plate_ids][:not_ready_to_QC].push yid
          end
        end

        ready_conditions = sample_check && t[:yeast_plate_ids][:ready_to_QC].length == t.simple_spec[:yeast_plate_ids].length
      end

      if ready_conditions
        t.status = "ready"
        t.save
      else
        t.status = "waiting"
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

  def arguments
    {
      io_hash: {},
      debug_mode: "Yes",
      task_name: "Yeast Strain QC",
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

    waiting_users = tasks[:waiting_ids].collect { |tid| find(:task, id: tid)[0].user.name }
    ready_users = tasks[:ready_ids].collect{ |tid| find(:task, id: tid)[0].user.name }

    show {

      title "Task status"
      note "For #{io_hash[:task_name]} tasks that belong to #{io_hash[:group]}:"

      if tasks[:waiting_ids].length > 0
        note "Waiting tasks are:" 
        table [[ "Waiting task", "Tasks owner"]].concat(tasks[:waiting_ids].zip waiting_users)
      else
        note "No task is wating"
      end

      if tasks[:ready_ids].length > 0
        note "Ready tasks are:"
        table [[ "Ready tasks", "Tasks owner"]].concat(tasks[:ready_ids].zip ready_users)
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

      # Add sequence correct items to make glycerol stocks
      seq_verifi_tasks = find(:task, { task_prototype: { name: "Sequencing Verification" } })
      correct_seq_verifi_tasks = seq_verifi_tasks.select { |t| t.status == "sequence correct" }
      correct_seq_verifi_tasks.each do |task|
        io_hash[:task_ids].push task.id
        io_hash[:overnight_ids].concat task.simple_spec[:overnight_ids]
      end

    when "Discard Item"
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:item_ids].concat task.simple_spec[:item_ids]
      end

      # Add sequence wrong items to discard
      seq_verifi_tasks = find(:task, { task_prototype: { name: "Sequencing Verification" } })
      wrong_seq_verifi_tasks = seq_verifi_tasks.select { |t| t.status == "sequence wrong" }
      wrong_seq_verifi_tasks.each do |task|
        io_hash[:task_ids].push task.id
        io_hash[:item_ids].concat task.simple_spec[:plasmid_stock_ids]
        io_hash[:item_ids].concat task.simple_spec[:overnight_ids]
      end

    when "Streak Plate"
      io_hash[:yeast_glycerol_stock_ids] = []
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.simple_spec[:item_ids].each do |id|
          if find(:item, id: id)[0].object_type.name == "Yeast Glycerol Stock"
            io_hash[:yeast_glycerol_stock_ids].concat task.simple_spec[:item_ids]
          elsif ["Yeast Plate", "Plate"].include? find(:item, id: id)[0].object_type.name
            io_hash[:plate_ids].concat task.simple_spec[:item_ids]
          else 
            io_hash[:item_ids].concat task.simple_spec[:item_ids]
          end
        end
      end

    when "Gibson Assembly"
      if tasks[:fragments]
        waiting_ids = tasks[:waiting_ids]
        users = waiting_ids.collect { |tid| find(:task, id: tid)[0].user.name }
        fragment_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:fragments] }
        ready_to_use_fragment_ids = tasks[:fragments][:ready_to_use].uniq
        not_ready_to_use_fragment_ids = tasks[:fragments][:not_ready_to_use].uniq
        ready_to_build_fragment_ids = tasks[:fragments][:ready_to_build].uniq
        not_ready_to_build_fragment_ids = tasks[:fragments][:not_ready_to_build].uniq
        plasmid_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:plasmid] }
        plasmids = plasmid_ids.collect { |pid| find(:sample, id: pid)[0]}
        tasks_tab = [[ "Not ready tasks", "Tasks owner", "Plasmid", "Fragments", "Ready to build", "Not ready to build", "Length info missing" ]]
        waiting_ids.each_with_index do |tid,idx|
          tasks_tab.push [ tid, users[idx], "#{plasmids[idx]}", fragment_ids[idx].to_s, (fragment_ids[idx]&ready_to_build_fragment_ids).to_s, (fragment_ids[idx]&not_ready_to_build_fragment_ids).to_s,(fragment_ids[idx]&not_ready_to_use_fragment_ids).to_s ]
        end
        show {
          title "Gibson Assemby Status"
          note "Ready to build means recipes and ingredients for building this fragments are complete." 
          note "Not ready to build means some information or stocks are missing."
          note "Length info missing means the fragment are already in stock but does not have length information needed for Gibson assembly."
          table tasks_tab
        }
      end
      if io_hash[:group] != "technicians"
        io_hash[:task_ids] = io_hash[:task_ids].take(12)
      end
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:fragment_ids].push task.simple_spec[:fragments]
        io_hash[:plasmid_ids].push task.simple_spec[:plasmid]
      end

    when "Fragment Construction"
      fs = task_status name: "Fragment Construction", group: io_hash[:group]
      if fs[:fragments] && fs[:fragments][:not_ready_to_build].length > 0
        waiting_ids = fs[:waiting_ids]
        users = waiting_ids.collect { |tid| find(:task, id: tid)[0].user.name }
        fragment_ids = waiting_ids.collect { |tid| find(:task, id: tid)[0].simple_spec[:fragments] }
        ready_to_build_fragment_ids = fs[:fragments][:ready_to_build].uniq
        not_ready_to_build_fragment_ids = fs[:fragments][:not_ready_to_build].uniq
        fs_tab = [[ "Not ready tasks", "Tasks owner", "Fragments", "Ready to build", "Not ready to build" ]]
        waiting_ids.each_with_index do |tid,idx|
          fs_tab.push [ tid, users[idx], fragment_ids[idx].to_s, (fragment_ids[idx]&ready_to_build_fragment_ids).to_s, (fragment_ids[idx]&not_ready_to_build_fragment_ids).to_s ]
        end
        show {
          title "Fragment Construction Status"
          note "Ready to build means recipes and ingredients for building this fragments are complete. Not ready to build means some information or stocks are missing."
          table fs_tab
        }
      end

      # pull out fragments that need to be made from Gibson Assembly tasks
      gibson_tasks = task_status name: "Gibson Assembly", group: io_hash[:group]
      io_hash[:fragment_ids].concat gibson_tasks[:fragments][:ready_to_build] if gibson_tasks[:fragments]
      io_hash[:fragment_ids].uniq!

      # pull out fragments from Fragment Construction tasks and cut off based on limits for non tech groups
      limit_idx = io_hash[:task_ids].length
      io_hash[:task_ids].each_with_index do |tid,idx|
        task = find(:task, id: tid)[0]
        fragment_ids_temp = io_hash[:fragment_ids].dup
        io_hash[:fragment_ids].concat task.simple_spec[:fragments]
        io_hash[:fragment_ids].uniq!
        if io_hash[:fragment_ids].length > 10 && io_hash[:group] != "technicians"
          limit_idx = idx
          io_hash[:fragment_ids] = fragment_ids_temp
          break
        end
      end
      io_hash[:task_ids] = io_hash[:task_ids].take(limit_idx)

    when "Plasmid Verification"
      io_hash = { num_colonies: [], primer_ids: [], initials: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:plate_ids].concat task.simple_spec[:plate_ids]
        io_hash[:num_colonies].concat task.simple_spec[:num_colonies]
        io_hash[:primer_ids].concat task.simple_spec[:primer_ids]
        io_hash[:initials].concat [task.simple_spec[:initials]]*(task.simple_spec[:plate_ids].length)
      end

    when "Yeast Strain QC"
      io_hash = { yeast_plate_ids: [], num_colonies: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:yeast_plate_ids].concat task.simple_spec[:yeast_plate_ids]
        io_hash[:num_colonies].concat task.simple_spec[:num_colonies]
      end

    else
      show {
        title "Under development"
        note "The input checking Protocol for this task #{io_hash[:task_name]} is still under development."
      }
    end

    show {
      title "Tasks inputs processed!"
      note "#{io_hash[:task_name]} tasks inputs have been successfully processed and please work on the next protocol in the flow! Cheers!"
    }

    return { io_hash: io_hash }
  end

end 