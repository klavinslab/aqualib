module Tasking

  def find_tasks p={}
    params = { task_prototype_name: "", group: "" }.merge p
    tasks = find(:task,{ task_prototype: { name: params[:task_prototype_name] } }).select {
    |t| %w[waiting ready].include? t.status }
    # filter out tasks based on group input
    unless params[:group].empty?
      user_group = params[:group] == "technicians"? "cloning": params[:group]
      group_info = Group.find_by_name(user_group)
      tasks.select! { |t| t.user.member? group_info.id }
    end
    return tasks
  end
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

    if block_given?
      user_shows = ShowBlock.new.run(&Proc.new)
    else
      user_shows = []
    end

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
      raw user_shows
    }
    limit_input[:limit] ||= sizes[-1] # a||a = b
    limit_num = limit_input[:limit].to_i
    limit_idx = sizes.index(limit_num)
    # show {
    #   note "limit_idx is #{limit_idx}"
    #   note "limit_num is #{limit_num}"
    #   note "size is #{sizes}"
    # }
    if sizes[-1] == sizes.index(sizes[-1]) && limit_num < sizes[-1]
      # this means each tasks only contain one unit
      # We will select tasks based on users and the limit num
      user_task_hash = Hash.new {|h,k| h[k] = [] }
      task_ids.each do |tid|
        task = find(:task, id: tid)[0]
        user_task_hash[task.user.login] = user_task_hash[task.user.login].push tid
      end
      # give each user a priority based on the average limit
      num_of_user = user_task_hash.keys.length
      ave_limit = (limit_num/num_of_user).to_i
      task_ids_to_return = []
      remaining_capacity = limit_num # the initial remaining_capacity should be all
      while ave_limit > 0
        user_task_hash.each do |user, ids|
          task_ids_to_return.concat user_task_hash[user].take(ave_limit)
          user_task_hash[user] = user_task_hash[user].drop(ave_limit)
        end
        user_task_hash.delete_if { |k, v| v.empty? }
        num_of_user = user_task_hash.keys.length
        remaining_capacity = limit_num - task_ids_to_return.length
        ave_limit = (remaining_capacity/num_of_user).to_i
      end
      # use remaining_task_ids to fill up the remaining_capacity
      if remaining_capacity > 0
        remaining_task_ids = task_ids - task_ids_to_return
        task_ids_to_return.concat remaining_task_ids.take(remaining_capacity)
      end

    else # this means some tasks contain more than one unit
      task_ids_to_return =  task_ids.take(limit_idx)
    end

    # sort task_ids_to_return by user name
    sorted_task_ids = task_ids_to_return.sort_by { |tid| find(:task, id: tid)[0].user.id }

    return sorted_task_ids

  end

  # return the size of a task
  def task_size id
    task = find(:task, id: id)[0]
    task_prototype_name = task.task_prototype.name
    size = 0
    case task_prototype_name
    when "Gibson Assembly", "Yeast Mating"
      size = 1
    when "Agro Transformation"
      size = task.simple_spec[:plasmid_item_ids].length
    when "Fragment Construction", "Mutagenized Fragment Construction"
      size = task.simple_spec[:fragments].length
    when "Sequencing", "Primer Order"
      size = task.simple_spec[:primer_ids].flatten.length
    when "Plasmid Verification", "Yeast Strain QC", "E coli QC"
      size = task.simple_spec[:num_colonies].inject { |sum, i| sum + i }
    when "Cytometer Reading", "Glycerol Stock", "Discard Item", "Streak Plate"
      size = task.simple_spec[:item_ids].length
    when "Plasmid Combining"
      size = 1
    when "Yeast Transformation"
      size = task.simple_spec[:yeast_transformed_strain_ids].length
    when "Sequencing Verification"
      size = task.simple_spec[:plasmid_stock_ids].length
    when "Yeast Competent Cell", "Yeast Cytometry"
      size = task.simple_spec[:yeast_strain_ids].length
    when "Plasmid Extraction"
      size = task.simple_spec[:glycerol_stock_ids].length
    when "Ecoli Transformation"
      size = task.simple_spec[:plasmid_item_ids].length
    when "Golden Gate Assembly"
      size = 1
    when "Verification Digest", "Midiprep", "Maxiprep"
      size = 1
    when "Warming Agar"
      size = task.simple_spec[:media_type].length
    end
    return size
  end

  p = "aqualib/lib/task_checking.rb"
  s = Repo::version p
  content = Repo::contents p, s
  eval(content)

  def task_status tasks
    tasks = [tasks] unless tasks.is_a? Array
    new_task_ids = []
    tasks.each do |task|
      new_task_ids.concat task_status_check(task)[:new_task_ids]
    end
    return {
      waiting_ids: (tasks.select { |t| t.status == "waiting" })
      .collect { |t| t.id },
      ready_ids: (tasks.select { |t| t.status == "ready" })
      .collect {|t| t.id},
      new_task_ids: new_task_ids
    }
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
