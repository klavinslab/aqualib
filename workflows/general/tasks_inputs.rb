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
      else
        show {
          title "Under development"
          note "The input checking function for this task #{params[:name]} is still under development."
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
      waiting_ids: (tasks.select { |t| t.status == "waiting" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id},
    }
  end ### sequencing_status

  def arguments
    {
      io_hash: {},
      debug_mode: "Yes",
      task_name: "Glycerol Stock",
      group: "technicians"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", item_ids: [], yeast_item_ids:[], overnight_ids: [], plate_ids: [], task_name: "" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    show {
      title "#{io_hash}"
    }

    tasks = task_status name: io_hash[:task_name]
    io_hash[:task_ids] = tasks[:ready_ids]
    case io_hash[:task_name]
    when "Glycerol Stock"
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:item_ids].concat task.simple_spec[:item_ids]
      end
      io_hash[:item_ids].each do |id|
        if find(:item, id: id)[0].object_type.name.downcase.include? "overnight"
          io_hash[:overnight_ids].push id
        elsif find(:item, id: id)[0].object_type.name.downcase.include? "plate"
          io_hash[:yeast_item_ids].push id
        end
      end
    else
      show {
        title "Under development"
        note "The input checking Protocol for this task #{io_hash[:task_name]} is still under development."
      }
    end

    show {
      title "io_hash"
      note "#{io_hash}"
    }

    return { io_hash: io_hash }
  end

end  