needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

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
    io_hash_default = Hash.new(Array.new)
    io_hash = io_hash_default.merge io_hash  # make io_hash default value []

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # automatic task submissions
    if ["Discard Item", "Glycerol Stock"].include? io_hash[:task_name]
      show_tasks_table(sequencing_verification_task_processing group: io_hash[:group])
    end

    # process task_status
    tasks = task_status name: io_hash[:task_name], group: io_hash[:group]

    # show the users about newly created and adjusted tasks
    show_tasks_table tasks[:new_task_ids]

    wating_tab = task_info_table tasks[:waiting_ids]
    ready_tab = task_info_table tasks[:ready_ids]

    show {
      title "Task status"
      note "For #{io_hash[:task_name]} tasks that belong to #{io_hash[:group]}:"
      note "Waiting tasks quantity: #{tasks[:waiting_ids].length}"
      table wating_tab
      note "Ready tasks quantity: #{tasks[:ready_ids].length}"
      table ready_tab
    }

    # task sizes limit choose
    io_hash[:task_ids] = task_choose_limit(tasks[:ready_ids], io_hash[:task_name])

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
      io_hash[:size] = io_hash[:overnight_ids].length + io_hash[:item_ids].length

    when "Streak Plate"
      io_hash = { yeast_plate_ids:[], yeast_glycerol_stock_ids:[] }.merge io_hash
      io_hash[:yeast_glycerol_stock_ids] = []
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.simple_spec[:item_ids].each do |id|
          if find(:item, id: id)[0].object_type.name == "Yeast Glycerol Stock"
            io_hash[:yeast_glycerol_stock_ids].push id
          elsif ["Yeast Plate"].include? find(:item, id: id)[0].object_type.name
            io_hash[:yeast_plate_ids].concat task.simple_spec[:item_ids]
          end
        end
      end
      io_hash[:size] = io_hash[:yeast_glycerol_stock_ids].length + io_hash[:yeast_plate_ids].length

    when "Gibson Assembly"
      io_hash = { fragment_ids: [], plasmid_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:fragment_ids].push task.simple_spec[:fragments]
        io_hash[:plasmid_ids].push task.simple_spec[:plasmid]
      end
      io_hash[:size] = io_hash[:plasmid_ids].length

    when "Plasmid Verification"
      io_hash = { num_colonies: [], plate_ids: [], primer_ids: [], initials: [], glycerol_stock_ids: [] }.merge io_hash

      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:plate_ids].concat task.simple_spec[:plate_ids]
        io_hash[:num_colonies].concat task.simple_spec[:num_colonies]
        io_hash[:primer_ids].concat task.simple_spec[:primer_ids]
      end
      # Add plasmid extraction tasks here to do overnight and miniprep in one batch
      plasmid_extraction_tasks = task_status name: "Plasmid Extraction", group: io_hash[:group]
      io_hash[:plasmid_extraction_task_ids] = task_choose_limit(plasmid_extraction_tasks[:ready_ids], "Plasmid Extraction")
      io_hash[:plasmid_extraction_task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:glycerol_stock_ids].concat task.simple_spec[:glycerol_stock_ids]
      end
      io_hash[:task_ids].concat io_hash[:plasmid_extraction_task_ids]
      io_hash[:size] = io_hash[:num_colonies].inject { |sum, n| sum + n } || 0 + io_hash[:glycerol_stock_ids].length

    when "Primer Order", "Discard Item", "Yeast Competent Cell", "Fragment Construction", "Yeast Cytometry"
      # a general task processing script only works for those tasks with one variable_name
      io_hash[:task_ids].each_with_index do |tid, idx|
        task = find(:task, id: tid)[0]
        task.simple_spec.each do |variable_name, ids|
          variable_name = :fragment_ids if variable_name == :fragments
          io_hash[variable_name] = [] if idx == 0
          io_hash[variable_name].concat ids
          if idx == io_hash[:task_ids].length - 1
            io_hash[variable_name].uniq!
            io_hash[:size] = io_hash[variable_name].length
          end
        end
      end
      # additional io_hash key: values
      io_hash[:volume] = 2 if io_hash[:task_name] == "Yeast Competent Cell"

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
        note "The following tasks inputs has been processed, batched and returned as outputs. The total batch size is #{io_hash[:size]}."
        table tasks_tab
      else
        note "No task's input is returned as outputs"
      end
    }

    return { io_hash: io_hash }
  end

end
