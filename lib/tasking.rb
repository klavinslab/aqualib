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
    when "Gibson Assembly", "Yeast Mating"
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
    when "Yeast Competent Cell", "Yeast Cytometry"
      size = task.simple_spec[:yeast_strain_ids].length
    when "Plasmid Extraction"
      size = task.simple_spec[:glycerol_stock_ids].length
    when "Ecoli Transformation"
      size = task.simple_spec[:plasmid_item_ids].length
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
