module Cloning

  def fragment_info fid

    # This method returns information about the ingredients needed to make the fragment with id fid.
    # It returns a hash containing a list of stocks of the fragment, length of the fragment, as well item numbers for forward, reverse primers and plasmid template (1 ng/µL Plasmid Stock). It also computes the annealing temperature.

    # find the fragment and get its properties
    fragment = find(:sample,{id: fid})[0]
    props = fragment.properties

    # get sample ids for primers and template
    fwd = props["Forward Primer"]
    rev = props["Reverse Primer"]
    template = props["Template"]

    # get length for each fragment
    length = props["Length"]

    if fwd == nil || rev == nil || template == nil

      return nil # Whoever entered this fragment didn't provide infor on how to make it

    else

      # get items associated with primers and template
      fwd_items = fwd.in "Primer Aliquot"
      rev_items = rev.in "Primer Aliquot"
      template_items = template.in "1 ng/µL Plasmid Stock"

      if fwd_items.length == 0 || rev_items.length == 0 || template_items.length == 0

        return nil # There are missing items

      else

        # compute the annealing temperature
        t1 = fwd_items[0].sample.properties["T Anneal"] || 70.0
        t2 = rev_items[0].sample.properties["T Anneal"] || 70.0

        # find stocks of this fragment, if any
        stocks = fragment.items.select { |i| i.object_type.name == "Fragment Stock" && i.location != "deleted"}

        return {
          fragment: fragment,
          stocks: stocks,
          length: length,
          fwd: fwd_items[0],
          rev: rev_items[0],
          template: template_items[0],
          tanneal: (t1+t2)/2.0
        }

      end

    end

  end # # # # # # # 

  def gibson_assembly_status

    # find all un done gibson assembly tasks ans arrange them into lists by status
    tasks = find(:task,{task_prototype: { name: "Gibson Assembly" }})
    waiting = tasks.select { |t| t.status == "waiting for fragments" }
    ready = tasks.select { |t| t.status == "ready" }
    running = tasks.select { |t| t.status == "running" }
    out = tasks.select { |t| t.status == "out for sequencing" }

    # look up all fragments needed to assemble, and sort them by whether they are ready to build, etc.
    waiting.each do |t|

      show {
        note "Before processing"
        note "#{t}"
      }

      t[:fragments] = { ready_to_use: [], ready_to_build: [], not_ready_to_build: [] }

      t.simple_spec[:fragments].each do |fid|

        info = fragment_info fid

        if !info
          t[:fragments][:not_ready_to_build].push fid
        elsif info[:stocks].length > 0
          t[:fragments][:ready_to_use].push fid
        else
          t[:fragments][:ready_to_build].push fid
        end

      end

      show {
        note "After processing"
        note "#{t[:fragments]}"
      }

    end

    # # look up all the plasmids that are ready to build and return fragment array.
    # ready.each do |r|

    #   r

    # return a big hash describing the status of all un-done assemblies
    return {

      fragments: ((tasks.select { |t| t.status == "waiting for fragments" }).collect { |t| t[:fragments] })
        .inject { |all,part| all.each { |k,v| all[k].concat part[k] } },

      assemblies: {
        under_construction: running.collect { |t| t.id },
        waiting_for_ingredients: (ready.select { |t| t[:fragments][:ready_to_build] != [] || t[:fragments][:not_ready_to_build] != [] }).collect { |t| t.id },
        ready_to_build: (ready.select { |t| t[:fragments][:ready_to_build] == [] && t[:fragments][:not_ready_to_build] == [] }).collect { |t| t.id },
        out_for_sequencing: out.collect { |t| t.id }
        }

    }

  end # # # # # # # 

end


