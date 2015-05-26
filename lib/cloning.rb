needs "aqualib/lib/standard"

module Cloning

  def self.included klass
    klass.class_eval do
      include Standard
    end
  end

  def fragment_info fid, p={}

    # This method returns information about the ingredients needed to make the fragment with id fid.
    # It returns a hash containing a list of stocks of the fragment, length of the fragment, as well item numbers for forward, reverse primers and plasmid template (1 ng/µL Plasmid Stock). It also computes the annealing temperature.

    # find the fragment and get its properties
    params = ({ item_choice: false, task_id: nil, check_mode: false }).merge p

    if params[:task_id]
      task = find(:task, id: params[:task_id])[0]
    end

    fragment = find(:sample,{id: fid})[0]
    if fragment == nil
      task.notify "Fragment #{fid} is not in the database.", job_id: jid if task
      return nil
    end
    props = fragment.properties

    # get sample ids for primers and template
    fwd = props["Forward Primer"]
    rev = props["Reverse Primer"]
    template = props["Template"]

    # get length for each fragment
    length = props["Length"]

    if fwd == nil
      task.notify "Forward Primer for fragment #{fid} required", job_id: jid if task
    end

    if rev == nil
      task.notify "Reverse Primer for fragment #{fid} required", job_id: jid if task
    end

    if template == nil
      task.notify "Template for fragment #{fid} required", job_id: jid if task
    end

    if length == nil
      task.notify "Length for fragment #{fid} required", job_id: jid if task
    end


    if fwd == nil || rev == nil || template == nil || length == 0

      return nil # Whoever entered this fragment didn't provide enough information on how to make it

    else

      if fwd.properties["T Anneal"] == nil || fwd.properties["T Anneal"] < 50
        task.notify "T Anneal (higher than 50) for primer #{fwd.id} of fragment #{fid} required", job_id: jid if task
      end

      if rev.properties["T Anneal"] == nil || rev.properties["T Anneal"] < 50
        task.notify "T Anneal (higher than 50) for primer #{rev.id} of fragment #{fid} required", job_id: jid if task
      end

      if fwd.properties["T Anneal"] == nil || fwd.properties["T Anneal"] < 50 || rev.properties["T Anneal"] == nil || rev.properties["T Anneal"] < 50
        return nil
      end

      # get items associated with primers and template
      fwd_items = fwd.in "Primer Aliquot"
      rev_items = rev.in "Primer Aliquot"
      if template.sample_type.name == "Plasmid"
        template_items = template.in "1 ng/µL Plasmid Stock"
        if template_items.length == 0 && template.in("Plasmid Stock").length == 0
          template_items = template.in "Gibson Reaction Result"
        end
      elsif template.sample_type.name == "Fragment"
        template_items = template.in "1 ng/µL Fragment Stock"
      elsif template.sample_type.name == "E coli strain"
        template_items = template.in "E coli Lysate"
        if template_items.length == 0
          template_items = template.in "Genome Prep"
        end
      elsif template.sample_type.name == "Yeast Strain"
        template_items = template.in "Lysate"
        if template_items.length == 0
          template_items = template.in "Yeast cDNA"
        end
      end

      if fwd_items.length == 0
        task.notify "Primer aliquot for primer #{fwd.id} of fragment #{fid} required", job_id: jid if task
      end

      if rev_items.length == 0
        task.notify "Primer aliquot for primer #{rev.id} of fragment #{fid} required", job_id: jid if task
      end

      if template_items.length == 0
        task.notify "Stock for template #{template.id} of fragment #{fid} required", job_id: jid if task
      end

      if fwd_items.length == 0 || rev_items.length == 0 || template_items.length == 0

        return nil # There are missing items

      else

        if !params[:check_mode]

          if params[:item_choice]
            fwd_item_to_return = choose_sample fwd_items[0].sample.name, object_type: "Primer Aliquot"
            rev_item_to_return = choose_sample rev_items[0].sample.name, object_type: "Primer Aliquot"
            template_item_to_return = choose_sample template_items[0].sample.name, object_type: template_items[0].object_type.name
          else
            fwd_item_to_return = fwd_items[0]
            rev_item_to_return = rev_items[0]
            template_item_to_return = template_items[0]
          end

          # compute the annealing temperature
          t1 = fwd_items[0].sample.properties["T Anneal"]
          t2 = rev_items[0].sample.properties["T Anneal"]

          # find stocks of this fragment, if any
          #stocks = fragment.items.select { |i| i.object_type.name == "Fragment Stock" && i.location != "deleted"}

          return {
            fragment: fragment,
            #stocks: stocks,
            length: length,
            fwd: fwd_item_to_return,
            rev: rev_item_to_return,
            template: template_item_to_return,
            tanneal: [t1,t2].min
          }

        else

          return true

        end

      end

    end

  end # # # # # # #

  def gibson_assembly_status p={}

    # find all un done gibson assembly tasks and arrange them into lists by status
    params = ({ group: false }).merge p
    tasks_all = find(:task,{task_prototype: { name: "Gibson Assembly" }})
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
    waiting = tasks.select { |t| t.status == "waiting for fragments" }
    ready = tasks.select { |t| t.status == "ready" }

    # look up all fragments needed to assemble, and sort them by whether they are ready to build, etc.
    (waiting + ready).each do |t|
      # show {
      #     note "#{t.simple_spec}"
      # }
      t[:fragments] = { ready_to_use: [], not_ready_to_use: [], ready_to_build: [], not_ready_to_build: [] }

      t.simple_spec[:fragments].each do |fid|

        info = fragment_info fid, task_id: t.id

        # First check if there already exists fragment stock and if its length info is entered, it's ready to build.
        if find(:sample, id: fid)[0].in("Fragment Stock").length > 0 && find(:sample, id: fid)[0].properties["Length"] > 0
          t[:fragments][:ready_to_use].push fid
        elsif find(:sample, id: fid)[0].in("Fragment Stock").length > 0 && find(:sample, id: fid)[0].properties["Length"] == 0
          t[:fragments][:not_ready_to_use].push fid
        elsif !info
          t[:fragments][:not_ready_to_build].push fid
        # elsif info[:stocks].length > 0
        #   t[:fragments][:ready_to_use].push fid
        else
          t[:fragments][:ready_to_build].push fid
        end

      end

    # change tasks status based on whether the fragments are ready and the plasmid info entered is correct.
      if t[:fragments][:ready_to_use].length == t.simple_spec[:fragments].length && find(:sample, id:t.simple_spec[:plasmid])[0]
        t.status = "ready"
        t.save
        # show {
        #   note "status changed to ready"
        #   note "#{t.id}"
        # }
      else
        t.status = "waiting for fragments"
        t.save
        # show {
        #   note "status changed to waiting"
        #   note "#{t.id}"
        # }
      end

      # show {
      #   note "After processing"
      #   note "#{t[:fragments]}"
      # }
    end

    # # # look up all the plasmids that are ready to build and return fragment array.
    # ready.each do |r|

    #   r[:fragments]

    # return a big hash describing the status of all un-done assemblies
    return {
      fragments: ((waiting + ready).collect { |t| t[:fragments] }).inject { |all,part| all.each { |k,v| all[k].concat part[k] } },
      waiting_ids: (tasks.select { |t| t.status == "waiting for fragments" }).collect { |t| t.id },
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect { |t| t.id },
      running_ids: (tasks.select { |t| t.status == "running" }).collect { |t| t.id },
      plated_ids: (tasks.select { |t| t.status == "plated" }).collect { |t| t.id },
      done_ids: (tasks.select { |t| t.status == "imaged and stored in fridge" }).collect { |t| t.id }
    }

  end # # # # # # #

  def fragment_construction_status
    # find all fragment construction tasks and arrange them into lists by status
    tasks = find(:task,{task_prototype: { name: "Fragment Construction" }})
    waiting = tasks.select { |t| t.status == "waiting for ingredients" }
    ready = tasks.select { |t| t.status == "ready" }
    running = tasks.select { |t| t.status == "running" }
    done = tasks.select { |t| t.status == "done" }

    (waiting + ready).each do |t|
      t[:fragments] = { ready_to_build: [], not_ready_to_build: [] }

      t.simple_spec[:fragments].each do |fid|

        info = fragment_info fid, task_id: t.id
        if !info
          t[:fragments][:not_ready_to_build].push fid
        else
          t[:fragments][:ready_to_build].push fid
        end

      end

      if t[:fragments][:ready_to_build].length == t.simple_spec[:fragments].length
        t.status = "ready"
        t.save
        # show {
        #   note "fragment construction status set to ready"
        #   note "#{t.id}"
        # }
      elsif t[:fragments][:ready_to_build].length < t.simple_spec[:fragments].length
        t.status = "waiting for ingredients"
        t.save
        # show {
        #   note "fragment construction status set to waiting"
        #   note "#{t.id}"
        # }
      end
    end

    return {
      fragments: ((waiting + ready).collect { |t| t[:fragments] }).inject { |all,part| all.each { |k,v| all[k].concat part[k] } },
      waiting_ids: (tasks.select { |t| t.status == "waiting for ingredients" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id},
      running_ids: running.collect {|t| t.id}
    }
  end ### fragment_construction_status

  def yeast_transformation_status p={}
    # find all yeast transformation tasks and arrange them into lists by status
    params = ({ group: false }).merge p
    tasks_all = find(:task,{task_prototype: { name: "Yeast Transformation" }})
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
    waiting = tasks.select { |t| t.status == "waiting for ingredients" }
    ready = tasks.select { |t| t.status == "ready" }
    (waiting + ready).each do |task|
      ready_yeast_strains = []
      task.simple_spec[:yeast_transformed_strain_ids].each do |yid|
        y = find(:sample, id: yid)[0]
        # check if glycerol stock and plasmid stock are ready
        parent_ready = y.properties["Parent"].in("Yeast Glycerol Stock").length > 0 || y.properties["Parent"].in("Yeast Plate").length > 0 || y.properties["Parent"].in("Yeast Competent Aliquot").length > 0 || y.properties["Parent"].in("Yeast Overnight Suspension").length > 0 || y.properties["Parent"].in("Yeast Competent Cell").length > 0
        plasmid_ready = y.properties["Integrant"].in("Plasmid Stock").length > 0 if y.properties["Integrant"]
        ready_yeast_strains.push y if parent_ready && plasmid_ready
      end
      if ready_yeast_strains.length == task.simple_spec[:yeast_transformed_strain_ids].length
        task.status = "ready"
        task.save
      else
        task.status = "waiting for ingredients"
        task.save
      end
    end # task_ids
    return {
      waiting_ids: (tasks.select { |t| t.status == "waiting for ingredients" }).collect { |t| t.id },
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect { |t| t.id },
      plated_ids: (tasks.select { |t| t.status == "plated" }).collect { |t| t.id },
      done_ids: (tasks.select { |t| t.status == "imaged and stored in fridge" }).collect { |t| t.id }
    }
  end ### yeast_transformation_status

  def load_samples_variable_vol headings, ingredients, collections # ingredients must be a string or number

    if block_given?
      user_shows = ShowBlock.new.run(&Proc.new)
    else
      user_shows = []
    end

    raise "Empty collection list" unless collections.length > 0

    heading = [ [ "#{collections[0].object_type.name}", "Location" ] + headings ]
    i = 0

    collections.each do |col|

      tab = []
      m = col.matrix

      (0..m.length-1).each do |r|
        (0..m[r].length-1).each do |c|
          if i < ingredients[0].length
            if m.length == 1
              loc = "#{c+1}"
            else
              loc = "#{r+1},#{c+1}"
            end
            tab.push( [ col.id, loc ] + ingredients.collect { |ing| { content: ing[i], check: true } } )
          end
          i += 1
        end
      end

      show {
          title "Load #{col.object_type.name} #{col.id}"
          table heading + tab
          raw user_shows
        }
    end

  end ### yeast_transformation_status

  def sequencing_status p={}
    params = ({ group: false }).merge p
    tasks_all = find(:task,{task_prototype: { name: "Sequencing" }})
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
    waiting = tasks.select { |t| t.status == "waiting for ingredients" }
    ready = tasks.select { |t| t.status == "ready" }
    running = tasks.select { |t| t.status == "send to sequencing" }
    done = tasks.select { |t| t.status == "results back" }

    # cycling through waiting and ready to make sure primer aliquots are in place

    (waiting + ready).each do |t|

      t[:primers] = { ready: [], no_aliquot: [] }

      t.simple_spec[:primer_ids].each do |prid|
        if find(:sample, id: prid)[0].in("Primer Aliquot").length > 0
          t[:primers][:ready].push prid
        else
          t[:primers][:no_aliquot].push prid
        end
      end

      if t[:primers][:ready].length == t.simple_spec[:primer_ids].length && find(:item, id: t.simple_spec[:plasmid_stock_id])
        t.status = "ready"
        t.save
      else
        t.status = "waiting for ingredients"
        t.save
      end
    end

    return {
      waiting_ids: (tasks.select { |t| t.status == "waiting for fragments" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id},
      running_ids: running.collect { |t| t.id },
      done_ids: done.collect { |t| t.id }
    }
  end ### sequencing_status

  def task_status p={}

    # This function is to process tasks of which the status is waiting or ready. If ready_condition of the task is met, set the status to ready, otherwise, set the status to waiting.
    # This function takes a hash as an argument. group defines whose tasks to process based on their owners belongings to the group and name defines which task_prototype of tasks to process. For example, group: technicians, name: "Yeast Strain QC" will process all Yeast Strain QC tasks whose owners belong to a group called cloning. Another example, group: yang, name: "Fragment Construction" will process all Fragment Construction tasks whose owner belong to a group called yang.

    params = ({ group: false, name: "", notification: "off" }).merge p
    raise "Supply a Task name for the task_status function as tasks_status name: task_name" if params[:name].length == 0
    tasks_all = find(:task,{task_prototype: { name: params[:name] }})
    tasks = []
    # filter out tasks based on group input
    if params[:group] && !params[:group].empty?
      user_group = params[:group] == "technicians"? "cloning": params[:group]
      group_info = Group.find_by_name(user_group)
      tasks_all.each do |t|
        if t.user
          tasks.push t if t.user.member? group_info.id
        end
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
          if find(:item, id: id)[0]
            if accepted_object_types.include? find(:item, id: id)[0].object_type.name
              t[:item_ids][:ready].push id
            else
              t[:item_ids][:not_ready].push id
            end
          end
        end
        ready_conditions = t[:item_ids][:ready].length == t.simple_spec[:item_ids].length

      when "Gibson Assembly"
        t[:fragments] = { ready_to_use: [], not_ready_to_use: [], need_to_build: []}
        t.simple_spec[:fragments].each do |fid|
          # info = fragment_info fid, check_mode: true
          # info = true
          # First check if there already exists fragment stock and if its length info is entered, it's ready to build.
          fragment = find(:sample, id: fid)[0]
          if fragment == nil
            t[:fragments][:not_ready_to_use].push fid
            t.notify "Fragment #{fid} does not exist in database.", job_id: jid
          elsif fragment.in("Fragment Stock").length > 0 && fragment.properties["Length"] > 0
            t[:fragments][:ready_to_use].push fid
          elsif fragment.in("Fragment Stock").length > 0 && fragment.properties["Length"] == 0
            t[:fragments][:not_ready_to_use].push fid
          else
            t[:fragments][:need_to_build].push fid
          end
        end
        plasmid_condition = false
        plasmid = find(:sample, id: t.simple_spec[:plasmid])[0]
        if plasmid
          bacterial_marker = plasmid.properties["Bacterial Marker"]
          bacterial_marker = "" if !bacterial_marker
          plasmid_condition = !bacterial_marker.empty?
          t.notify "Bacterial Marker info required for plasmid #{t.simple_spec[:plasmid]}", job_id: jid if bacterial_marker.empty?
        else
          t.notify "No samples corresponding to plasmid #{t.simple_spec[:plasmid]}", job_id: jid
        end
        ready_conditions = t[:fragments][:ready_to_use].length == t.simple_spec[:fragments].length && plasmid_condition

      when "Fragment Construction"
        t[:fragments] = { ready_to_build: [], not_ready_to_build: [] }
        t.simple_spec[:fragments].each do |fid|
          if params[:notification].downcase == "off"
            info = fragment_info fid, check_mode: true
          else
            info = fragment_info fid, task_id: t.id, check_mode: true
          end

          if !info
            t[:fragments][:not_ready_to_build].push fid
          else
            t[:fragments][:ready_to_build].push fid
          end
        end
        ready_conditions = t[:fragments][:ready_to_build].length == t.simple_spec[:fragments].length

      when "Plasmid Verification"
        length_check = t.simple_spec[:plate_ids].length == t.simple_spec[:num_colonies].length && t.simple_spec[:plate_ids].length == t.simple_spec[:primer_ids].length
        t.notify "plate_ids, num_colonies, primer_ids need to have the same array length." if !length_check
        t[:plate_ids] = { ready: [], not_ready: [] }
        t.simple_spec[:plate_ids].each_with_index do |pid,idx|
          if find(:item, id: pid)[0]
            plate_ready = ["E coli Plate of Plasmid", "Plasmid Glycerol Stock"].include?(find(:item, id: pid)[0].object_type.name)
            marker_ready = (find(:item, id: pid)[0].sample.properties["Bacterial Marker"] || "").length > 0
            num_colonies_ready = (t.simple_spec[:num_colonies][idx] || 0).between?(0, 10)

            if plate_ready && marker_ready && num_colonies_ready
              t[:plate_ids][:ready].push pid
            else
              t[:plate_ids][:not_ready].push pid
              t.notify "Item #{pid} need to be an E coli Plate of Plasmid or Plasmid Glycerol Stock", job_id: jid if !plate_ready
              t.notify "Need Bacterial Marker info for sample corresponding to item #{pid}", job_id: jid if !marker_ready
              t.notify "num_colonies for #{pid} need to be a number between 0,10", job_id: jid if !(t.simple_spec[:num_colonies][idx] || 0).between?(0, 10)
            end
          end
        end

        t[:primers] = { ready: [], no_aliquot: [] }
        primer_ids = t.simple_spec[:primer_ids].flatten.uniq
        primer_ids.each do |prid|
          if prid != 0
            primer = find(:sample, id: prid)[0]
            if primer
              if find(:sample, id: prid)[0].in("Primer Aliquot").length > 0
                t[:primers][:ready].push prid
              else
                t[:primers][:no_aliquot].push prid
                t.notify "Primer #{prid} has no primer aliquot.", job_id: jid
              end
            else
              t.notify "#{prid} is not a valid sample id.", job_id: jid
            end
          elsif prid == 0
            t[:primers][:ready].push prid
          end
        end

        ready_conditions = length_check && t[:plate_ids][:ready].length == t.simple_spec[:plate_ids].length && t[:primers][:ready].length == primer_ids.length

      when "Yeast Transformation"
        t[:yeast_strains] = { ready_to_build: [], not_ready_to_build: [] }
        t.simple_spec[:yeast_transformed_strain_ids].each do |yid|
          y = find(:sample, id: yid)[0]
          parent_ready, integrant_ready = nil, nil
          # check if competent aliquot/cell and plasmid stock are ready and send notifications
          if y
            if y.properties["Parent"]
              parent_ready = y.properties["Parent"].in("Yeast Competent Aliquot").length > 0 || y.properties["Parent"].in("Yeast Competent Cell").length > 0
              t.notify "No competent aliquot/cell for the parent strain of #{y}. Competent cells will be made when yeast competent cell workflow got run.", job_id: jid if !parent_ready
            else
              parent_ready = nil
              t.notify "Parent strain not defined", job_id: jid
            end

            if y.properties["Integrant"]
              integrant = y.properties["Integrant"]
              if integrant.sample_type.name == "Plasmid" && integrant.properties["Yeast Marker"]
                integrant_ready = integrant.in("Plasmid Stock").length > 0 && !integrant.properties["Yeast Marker"].empty?
              elsif integrant.sample_type.name == "Fragment" && integrant.properties["Yeast Marker"]
                integrant_ready = integrant.in("Fragment Stock").length > 0 && !integrant.properties["Yeast Marker"].empty?
              end
              t.notify "No stock exists or lack of Yeast Marker info for #{integrant.name}, integrant of yeast strain #{y}", job_id: jid if !integrant_ready
            else
              t.notify "No integrant defined for yeast strain #{y}.", job_id: jid
            end
          else
            t.notify "Invalid yeast_transformed_strain_id #{yid}", job_id: jid
          end

          if parent_ready && integrant_ready
            t[:yeast_strains][:ready_to_build].push yid
          else
            t[:yeast_strains][:not_ready_to_build].push yid
          end
        end

        ready_conditions = t[:yeast_strains][:ready_to_build].length == t.simple_spec[:yeast_transformed_strain_ids].length

      when "Yeast Strain QC"
        length_check = t.simple_spec[:yeast_plate_ids].length == t.simple_spec[:num_colonies].length
        t.notify "yeast_plate_ids need to have the same array length with num_colonies.", job_id: jid if !length_check
        t[:yeast_plate_ids] = { ready_to_QC: [], not_ready_to_QC: [] }
        t.simple_spec[:yeast_plate_ids].each_with_index do |yid, idx|
          primer1 = nil
          primer2 = nil
          primer1 = find(:item, id: yid)[0].sample.properties["QC Primer1"].in("Primer Aliquot")[0] if find(:item, id: yid)[0].sample.properties["QC Primer1"]
          primer2 = find(:item, id: yid)[0].sample.properties["QC Primer2"].in("Primer Aliquot")[0] if find(:item, id: yid)[0].sample.properties["QC Primer2"]
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

      when "Sequencing"
        t[:primers] = { ready: [], no_aliquot: [] }

        primer_ids = t.simple_spec[:primer_ids].flatten.uniq

        primer_ids.each do |prid|
          if find(:sample, id: prid)[0].in("Primer Aliquot").length > 0
            t[:primers][:ready].push prid
          else
            t[:primers][:no_aliquot].push prid
            t.notify "Primer #{prid} has no primer aliquot.", job_id: jid
          end
        end

        ready_conditions = t[:primers][:ready].length == primer_ids.length && find(:item, id: t.simple_spec[:plasmid_stock_id])

      when "Yeast Mating"
        t[:yeast_strains] = { ready: [], not_valid:[] }

        t.simple_spec[:yeast_mating_strain_ids].each do |yid|
          if find(:sample, id: yid )[0].in("Yeast Glycerol Stock").length > 0
            t[:yeast_strains][:ready].push yid
          else
            t[:yeast_strains][:not_valid].push yid
          end
        end

        ready_conditions = t[:yeast_strains][:ready].length == 2 && t.simple_spec[:yeast_mating_strain_ids].length == 2 && t.simple_spec[:yeast_selective_plate_type].is_a?(String)

      when "Yeast Competent Cell"
        t[:yeast_strains] = { ready: [], not_valid:[], ready_to_streak: [], not_ready_to_streak: [] }

        t.simple_spec[:yeast_strain_ids].each do |yid|
          if (collection_type_contain yid, "Divided Yeast Plate", 60).length > 0
            t[:yeast_strains][:ready].push yid
          else
            t[:yeast_strains][:not_valid].push yid
            y = find(:sample, id: yid)[0]
            if y
              if (y.in "Yeast Glycerol Stock").length > 0
                t[:yeast_strains][:ready_to_streak].push yid
                t.notify "No grown divided yeast plate for the strain of #{yid}. Divded yeast plate will be generated by Streak Plate workflow.", job_id: jid
              else
                t[:yeast_strains][:not_ready_to_streak].push yid
                t.notify "No grown divided yeast plate for the strain of #{yid}. Need glycerol stock in order to streak plate.", job_id: jid
              end
            end
          end
        end

        ready_conditions = t[:yeast_strains][:ready].length == t.simple_spec[:yeast_strain_ids].length

      else
        show {
          title "Under development"
          note "The input checking function for this task #{params[:name]} is still under development."
          note "#{t.id}"
        }

      end

      if ready_conditions
        set_task_status(t, "ready") if t.status != "ready"
        t.save
      else
        set_task_status(t, "waiting") if t.status != "waiting"
        t.save
      end

    end

    task_status_hash = {
      waiting_ids: (tasks.select { |t| t.status == "waiting" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id}
    }

    task_status_hash[:fragments] = ((waiting + ready).collect { |t| t[:fragments] }).inject { |all,part| all.each { |k,v| all[k].concat part[k] } } if ["Gibson Assembly", "Fragment Construction"].include? params[:name]

    task_status_hash[:yeast_strains] = ((waiting + ready).collect { |t| t[:yeast_strains] }).inject { |all,part| all.each { |k,v| all[k].concat part[k] } } if ["Yeast Transformation","Yeast Competent Cell"].include? params[:name]

    return task_status_hash

  end ### task_status

  # a function that returns a table of task information
  def task_info_table task_ids

    task_ids.compact!

    if task_ids.length == 0
      return []
    end

    tab = [[ "Task ids", "Task type", "Task name", "Task owner" ]]

    task_ids.each do |tid|
      task = find(:task, id: tid)[0]
      tab.push [ tid, task.task_prototype.name, task.name, task.user.name ]
    end

    return tab

  end ### task_info_table

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

end
