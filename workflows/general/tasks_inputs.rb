needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      debug_mode: "Yes",
      task_name: "Plasmid Verification",
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

    else
      show {
        title "Under development"
        note "The input checking Protocol for this task #{io_hash[:task_name]} is still under development."
      }
    end

    show {
      title "Tasks inputs have been successfully processed!"
      note "#{io_hash[:task_name]} tasks inputs have been successfully processed and please work on the next protocol in the flow!"
    }

    return { io_hash: io_hash }
  end

end 