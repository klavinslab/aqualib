module Cloning

  def fragment_info fid, p={}

    # This method returns information about the ingredients needed to make the fragment with id fid.
    # It returns a hash containing a list of stocks of the fragment, length of the fragment, as well item numbers for forward, reverse primers and plasmid template (1 ng/µL Plasmid Stock). It also computes the annealing temperature.

    # find the fragment and get its properties
    params = ({ item_choice: false }).merge p

    fragment = find(:sample,{id: fid})[0]
    props = fragment.properties

    # get sample ids for primers and template
    fwd = props["Forward Primer"]
    rev = props["Reverse Primer"]
    template = props["Template"]

    # get length for each fragment
    length = props["Length"]

    if fwd == nil || rev == nil || template == nil || length == 0

      return nil # Whoever entered this fragment didn't provide enough information on how to make it

    else

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
      elsif template.sample_type.name == "Yeast Strain"
        template_items = template.in "Lysate"
      end

      if fwd_items.length == 0 || rev_items.length == 0 || template_items.length == 0

        return nil # There are missing items

      else

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
        t1 = fwd_items[0].sample.properties["T Anneal"] || 70.0
        t2 = rev_items[0].sample.properties["T Anneal"] || 70.0

        # find stocks of this fragment, if any
        stocks = fragment.items.select { |i| i.object_type.name == "Fragment Stock" && i.location != "deleted"}

        return {
          fragment: fragment,
          stocks: stocks,
          length: length,
          fwd: fwd_item_to_return,
          rev: rev_item_to_return,
          template: template_item_to_return,
          tanneal: (t1+t2)/2.0
        }

      end

    end

  end # # # # # # # 

  def gibson_assembly_status p={}

    # find all un done gibson assembly tasks ans arrange them into lists by status
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

        info = fragment_info fid

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

        info = fragment_info fid
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
  
  def yeast_transformation_status
    # process yeast transformation tasks ready and waiting based on information provided.
    tasks = find(:task,{ task_prototype: { name: "Yeast Transformation" } })
    waiting = tasks.select { |t| t.status == "waiting for ingredients" }
    ready = tasks.select { |t| t.status == "ready" }
    (waiting + ready).each do |task|
      ready_yeast_strains = []
      task.simple_spec[:yeast_transformed_strain_ids].each do |yid|
        y = find(:sample, id: yid)[0]
        # check if glycerol stock and plasmid stock are ready
        parent_ready = y.properties["Parent"].in("Yeast Glycerol Stock").length > 0 || y.properties["Parent"].in("Yeast Plate").length > 0
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
        }
    end

  end



end


