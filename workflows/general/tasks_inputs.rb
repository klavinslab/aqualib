needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def task_status p={}
    params = ({ group: false, name: "" }).merge p
    raise "Supply a Task name for the task_status function as tasks_status name: task_name" if params[:name].length == 0
    tasks_all = find(:task,{task_prototype: { name: params[:name] }})
    tasks = []
    # filter out tasks based on group input
    if params[:group]
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
      when "Glycerol Stock"
        t[:item_ids] = { ready: [], not_valid: [] }
        t.simple_spec[:item_ids].each do |id|
          if find(:item, id: id)[0].object_type.name.downcase.include? "overnight" or find(:item, id: id)[0].object_type.name.downcase.include? "plate"
            t[:item_ids][:ready].push id
          else
            t[:item_ids][:not_valid].push id
          end
        end
        ready_conditions = t[:item_ids][:ready].length == t.simple_spec[:item_ids].length
      when "Discard Item"
        t[:item_ids] = { belong_to_user: [], not_belong_to_user: [] }
        t.simple_spec[:item_ids].each do |id|
          if find(:item, id: id)[0].sample.owner == t.user.login
            t[:item_ids][:belong_to_user].push id
          else
            t[:item_ids][:not_belong_to_user].push id
          end
        end
        ready_conditions = t[:item_ids][:belong_to_user].length == t.simple_spec[:item_ids].length
      when "Streak Plate"
        t[:item_ids] = { ready: [], not_ready: [] }
        accepted_object_types = ["Yeast Glycerol Stock", "Yeast Plate", "Plate"]
        t.simple_spec[:item_ids].each do |id|
          if accepted_object_types.include? find(:item, id: id)[0].object_type.name
            t[:item_ids][:ready].push id
          else
            t[:item_ids][:not_ready].push id
          end
        end
        ready_conditions = t[:item_ids][:ready].length == t.simple_spec[:item_ids].length
      when "Gibson Assembly"
        t[:fragments] = { ready_to_use: [], not_ready_to_use: [], ready_to_build: [], not_ready_to_build: [] }
        t.simple_spec[:fragments].each do |fid|
          info = fragment_info fid
          # First check if there already exists fragment stock and if its length info is entered, it's ready to build.
          if find(:sample, id: fid)[0].in("Fragment Stock").length > 0 && find(:sample, id: fid)[0].properties["Length"] > 0
            t[:fragments][:ready_to_use].push fid
          elsif find(:sample, id: fid)[0].in("Fragment Stock").length > 0 && find(:sample, id: fid)[0].properties["Length"] == 0
            t[:fragments][:not_ready_to_use].push fid
          elsif !info
            t[:fragments][:not_ready_to_build].push fid
          else
            t[:fragments][:ready_to_build].push fid
          end
        end
        ready_conditions = t[:fragments][:ready_to_use].length == t.simple_spec[:fragments].length && find(:sample, id:t.simple_spec[:plasmid])[0]
      else
        show {
          title "Under development"
          note "The input checking function for this task #{params[:name]} is still under development."
          note "#{t.id}"
        }
      end

      if ready_conditions
        t.status = "ready"
        t.save
      else
        t.status = "waiting"
        t.save
      end

    end

    return {
      fragments: ((waiting + ready).collect { |t| t[:fragments] }).inject { |all,part| all.each { |k,v| all[k].concat part[k] } },
      waiting_ids: (tasks.select { |t| t.status == "waiting" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id},
    }
  end ### sequencing_status

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

    tasks = task_status name: io_hash[:task_name]
    io_hash[:task_ids] = tasks[:ready_ids]
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
    when "Discard Item"
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:item_ids].concat task.simple_spec[:item_ids]
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
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:fragment_ids].push task.simple_spec[:fragments]
        io_hash[:plasmid_ids].push task.simple_spec[:plasmid]
      end
    when "Fragment Construction"
      fs = fragment_construction_status
      if fs[:fragments]
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
    else
      show {
        title "Under development"
        note "The input checking Protocol for this task #{io_hash[:task_name]} is still under development."
      }
    end

    show {
      title "#{io_hash[:task_name]} tasks inputs have been successfully processed!"
      note "The io_hash is #{io_hash}"
    }

    return { io_hash: io_hash }
  end

end 