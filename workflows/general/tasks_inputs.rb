needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      debug_mode: "Yes",
      task_name: "Yeast Transformation",
      group: "technicians"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", task_name: "", task_ids: [], size: 0, group: "technicians" }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    raise "Supply a task_name." if io_hash[:task_name].empty?

    user_group = io_hash[:group] == "technicians"? "cloning": io_hash[:group]

    # add seqeuncing verification tasks to process if discard item or glycerol stock
    if ["Discard Item", "Glycerol Stock"].include? io_hash[:task_name]
      sequencing_verification_tasks = find(:task,{ task_prototype: { name: "Sequencing Verification" } }).select { |t| ["sequence correct", "sequence correct but keep plate", "sequence correct but redundant", "sequence wrong"].include? t.status }
      sequencing_verification_tasks.select! { |t| t.user.member? Group.find_by_name(user_group).id } unless user_group.empty?
      # show the users about newly created and adjusted tasks from sequencing verifications
      show_tasks_table task_status(sequencing_verification_tasks)[:new_task_ids]
    end

    # add old plates to discard in the Discard Item tasks
    if io_hash[:task_name] == "Discard Item"
      divided_yeast_plates_to_delete = items_beyond_days "Divided Yeast Plate", 80
      yeast_plates_to_delete = items_beyond_days "Yeast Plate", 80
      new_discard_item_task_ids = []
      divided_yeast_plates_to_delete.each do |p|
        # find the first sample id that is not -1 in the matrix
        sample_id = p.datum[:matrix].flatten().select { |i| i!=-1 }[0]
        sample = find(:sample, id: sample_id)[0]
        if sample
          new_discard_item_task_ids.concat create_new_tasks(p.id, task_name: "Discard Item", user_id: sample.user.id, budget_id: 1)[:new_task_ids]
        else
          new_discard_item_task_ids.concat create_new_tasks(p.id, task_name: "Discard Item", user_id: 5, budget_id: 1)[:new_task_ids]
        end
      end
      yeast_plates_to_delete.each do |p|
        new_discard_item_task_ids.concat create_new_tasks(p.id, task_name: "Discard Item", user_id: p.sample.user.id, budget_id: 1)[:new_task_ids]
      end
      show_tasks_table new_discard_item_task_ids
    end

    tasks_to_process = find(:task,{ task_prototype: { name: io_hash[:task_name] } }).select {
    |t| %w[waiting ready].include? t.status }

    # filter out tasks based on group input
    tasks_to_process.select! { |t| t.user.member? Group.find_by_name(user_group).id } unless user_group.empty?

    # process task_status
    tasks = task_status tasks_to_process

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

    # launch special task_choose_limit for certain cost thresholds
    if io_hash[:task_name] == "Primer Order"
      primers = tasks[:ready_ids].map { |tid|
        task = find(:task, id: tid)[0]
        task.simple_spec[:primer_ids].map { |pid| find(:sample, id: pid)[0] }
      }.flatten
      total_cost = primers.map { |p|
        length = (p.properties["Overhang Sequence"] + p.properties["Anneal Sequence"]).length
        if length <= 60
          Parameter.get_float("short primer cost") * length
        elsif length > 60 && length <= 90
          Parameter.get_float("medium primer cost") * length
        else
          Parameter.get_float("long primer cost") * length
        end
        }.inject(0) { |sum, x| sum + x }
      urgent_tasks = tasks[:ready_ids].map { |tid| find(:task, id: tid)[0] }.select do |t|
        (t.simple_spec[:urgent] && t.simple_spec[:urgent][0].downcase == "yes")
      end

      io_hash[:task_ids] = task_choose_limit(tasks[:ready_ids], io_hash[:task_name]) {
        note "The total cost for all #{tasks[:ready_ids].count} #{io_hash[:task_name]}s is $#{'%.2f' % total_cost}." if total_cost >= 50
        note "None of the #{io_hash[:task_name]}s is urgent." if urgent_tasks.empty?
        warning "#{urgent_tasks.count} of the #{tasks[:ready_ids].count} ready #{io_hash[:task_name]} tasks are urgent!" if urgent_tasks.any?
        warning "You don't have enough #{io_hash[:task_name]}s to surpass the $50 threshold. The total cost for all #{io_hash[:task_name]}s is $#{'%.2f' % total_cost}." if total_cost < 50 && total_cost != 0
      }

      if total_cost < 50
        shipping_cost = 15.0 / urgent_tasks.count
        urgent_tasks.each { |t|
          pt = make_purchase t, "Primer Order Shipping", shipping_cost, 0.0
          pt.notify "$#{'%.2f' % shipping_cost} was automatically charged to #{Budget.find(t.budget_id).name} for shipping costs of urgent Primer Order task #{task_html_link t}", job_id: jid
        }
      end
    else
      # task sizes limit choose
      io_hash[:task_ids] = task_choose_limit(tasks[:ready_ids], io_hash[:task_name])
    end

    case io_hash[:task_name]

    when "Glycerol Stock"
      io_hash = { overnight_ids: [], item_ids: [], yeast_plate_task_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.simple_spec[:item_ids].each do |id|
          if find(:item, id: id)[0].object_type.name.downcase.include? "overnight"
            io_hash[:overnight_ids].push id
          elsif find(:item, id: id)[0].object_type.name.downcase.include? "plate"
            io_hash[:item_ids].push id
            io_hash[:yeast_plate_task_ids].push tid
          end
        end
      end
      io_hash[:overnight_ids].uniq!
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

    when "Agro Transformation"
      io_hash = { plasmid_item_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:plasmid_item_ids].push task.simple_spec[:plasmid_item_ids]
      end
      io_hash[:size] = io_hash[:plasmid_item_ids].length

    when "Plasmid Verification"
      io_hash = { num_colonies: [], plate_ids: [], primer_ids: [], initials: [], glycerol_stock_ids: [], task_hash: [] }.merge io_hash

      io_hash[:task_ids].each do |tid|
        task_hash = {}
        task_hash[:task_id] = tid
        task = find(:task, id: tid)[0]
        io_hash[:plate_ids].concat task.simple_spec[:plate_ids]
        io_hash[:num_colonies].concat task.simple_spec[:num_colonies]
        io_hash[:primer_ids].concat task.simple_spec[:primer_ids]
        task_hash[:plate_ids] = task.simple_spec[:plate_ids]
        task_hash[:num_colonies] = task.simple_spec[:num_colonies]
        task_hash[:primer_ids] = task.simple_spec[:primer_ids]
      end
      # Add plasmid extraction tasks here to do overnight and miniprep in one batch
      plasmid_extraction_tasks = find_tasks task_prototype_name: "Plasmid Extraction", group: io_hash[:group]
      plasmid_extraction_tasks = task_status plasmid_extraction_tasks
      io_hash[:plasmid_extraction_task_ids] = task_choose_limit(plasmid_extraction_tasks[:ready_ids], "Plasmid Extraction")
      io_hash[:plasmid_extraction_task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:glycerol_stock_ids].concat task.simple_spec[:glycerol_stock_ids]
      end
      io_hash[:task_ids].concat io_hash[:plasmid_extraction_task_ids]
      io_hash[:size] = io_hash[:num_colonies].inject { |sum, n| sum + n } || 0 + io_hash[:glycerol_stock_ids].length

    when "Maxiprep"
      io_hash = { glycerol_stock_ids: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:glycerol_stock_ids].push task.simple_spec[:glycerol_stock_id]
      end
      io_hash[:size] = io_hash[:glycerol_stock_ids].length

    when "Primer Order", "Discard Item", "Yeast Competent Cell", "Fragment Construction", "Yeast Transformation"
      # a general task processing script only works for those tasks with one variable_name
      io_hash[:task_hash] = []
      io_hash[:task_ids].each_with_index do |tid, idx|
        task = find(:task, id: tid)[0]
        # store task_id and variable corresponding
        task_hash = {}
        task.simple_spec.each do |variable_name, ids|
          next if variable_name == :urgent
          variable_name = :fragment_ids if variable_name == :fragments
          io_hash[variable_name] = [] if idx == 0
          io_hash[variable_name].concat ids
          if idx == io_hash[:task_ids].length - 1
            if variable_name != :fragment_ids
              io_hash[variable_name].uniq!
            end
            io_hash[:size] = io_hash[variable_name].length
          end
          task_hash[variable_name] = ids[0]
        end
        task_hash[:task_id] = tid
        io_hash[:task_hash].push task_hash
      end
      # additional io_hash key: values
      io_hash[:volume] = 2 if io_hash[:task_name] == "Yeast Competent Cell"

    when "Yeast Cytometry", "Cytometer Reading"
      # a general task processing script without uniqing variable content.
      io_hash[:task_ids].each_with_index do |tid, idx|
        task = find(:task, id: tid)[0]
        task.simple_spec.each do |variable_name, ids|
          io_hash[variable_name] = [] if idx == 0
          io_hash[variable_name].concat ids
          if idx == io_hash[:task_ids].length - 1
            io_hash[:size] = io_hash[variable_name].length
          end
        end
      end

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

    when "Verification Digest"
      io_hash = { template_ids: [], enzymes: [], band_lengths: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:template_ids].push task.simple_spec[:template_id]
        io_hash[:enzymes].push task.simple_spec[:enzymes]
        io_hash[:band_lengths].push task.simple_spec[:band_lengths]
      end
      io_hash[:size] = 1

    when "Yeast Mating"
      io_hash = { yeast_mating_strain_ids: [], yeast_selective_plate_types: [], user_ids: [], antibiotic_plates: [] }.merge io_hash
      plate_hash = Hash.new { |hash, key| hash[key] = 0 }
      io_hash = { has_antibiotic: "no" }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        plate_type = task.simple_spec[:yeast_selective_plate_type]
        io_hash[:yeast_mating_strain_ids].push task.simple_spec[:yeast_mating_strain_ids]
        io_hash[:yeast_selective_plate_types].push plate_type
        io_hash[:user_ids].push task.user.id
        plate_hash[plate_type] = plate_hash[plate_type] + 1
        sample = find(:sample, id: plate_type)[0].name
        if sample.include?("clonNAT") || sample.include?("G418") || sample.include?("Hygro") || sample.include?("Bleo")
          io_hash[:has_antibiotic] = "yes"
          io_hash[:antibiotic_plates].push plate_type
        end
      end
      io_hash = { needs_plates: "no" }.merge io_hash
      overall_batches = find(:item, object_type: { name: "Agar Plate Batch" }).map{|b| collection_from b}            
      plate_hash.each do |key, val|
        plate_batch = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0] == find(:sample, id: key)[0]}
        if !plate_batch.blank?
          num = plate_batch.num_samples
        else
          num = 0
        end

        if num < (val / 4.0)
          io_hash[:needs_plates] = "yes"
          num_left = ((val / 4.0) - num) / 4.0
          if  num_left <= 8
            io_hash = { media_type: [key], quantity: [1], media_container: ["200 mL Agar"], size_agar: 1 }.merge io_hash
          elsif num_left <= 16
            io_hash = { media_type: [key], quantity: [1], media_container: ["400 mL Agar"], size_agar: 1 }.merge io_hash
          elsif num_left <= 24
            io_hash = { media_type: [key], quantity: [1, 1], media_container: ["400 mL Agar", "200 mL Agar"], size_agar: 2 }.merge io_hash
          elsif num_left <= 32
            io_hash = { media_type: [key], quantity: [2], media_container: ["400 mL Agar"], size_agar: 1 }.merge io_hash
          end
         end
      end
      io_hash[:size] = io_hash[:yeast_mating_strain_ids].length

    when "Warming Agar"
      io_hash = { media_container: [], media_type: [], quantity: [] }.merge io_hash
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        io_hash[:media_container].push task.simple_spec[:media_container]

        io_hash[:media_type].push task.simple_spec[:media_type]
        io_hash[:quantity].push task.simple_spec[:quantity]
      end
      io_hash[:size] = io_hash[:media_type].length

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
