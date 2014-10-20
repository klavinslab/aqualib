needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  # def debug args = {}
  #   arguments = { mode: false, }.merge args
  #   if arguments[:mode]
  #     def debug
  #       true
  #     end
  #   else
  #     def debug
  #       false
  #     end
  #   end
  # end

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
        show {
          note "fragment construction status set to ready"
          note "#{t.id}"
        }
      elsif t[:fragments][:ready_to_build].length < t.simple_spec[:fragments].length
        t.status = "waiting for ingredients"
        t.save
        show {
          note "fragment construction status set to waiting"
          note "#{t.id}"
        }
      end
    end

    return {
      waiting_ids: (tasks.select { |t| t.status == "waiting for fragments" }).collect {|t| t.id},
      ready_ids: (tasks.select { |t| t.status == "ready" }).collect {|t| t.id},
      running_ids: running.collect {|t| t.id}
    }
  end
          


  def arguments
    {
      io_hash: {},
      fragment_ids: [2061,2062],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = {}
    # io_hash = input if input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode]
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode] == "Yes"
      def debug
        true
      end
    end

    gibson_assembly = gibson_assembly_status
    fragment_from_gibson_ids = []
    fragment_from_gibson_ids = gibson_assembly[:fragments][:ready_to_build] if gibson_assembly[:fragments]

    fragment_construction = fragment_construction_status
    fragment_from_construction_ids = []
    fragment_construction[:ready_ids].each do |tid|
      ready_task = find(:task, id: tid)[0]
      fragment_from_construction_ids.concat ready_task.simple_spec[:fragments]
      ready_task.status = "running"
      ready_task.save
    end

    fragment_from_metacol_ids = input[:fragment_ids]
    io_hash[:fragment_ids] = (fragment_from_gibson_ids + fragment_from_construction_ids + fragment_from_metacol_ids).uniq

    show {
      title "List of fragment ids ready to build"
      note "From Gibson Assembly tasks the following #{fragment_from_gibson_ids}"
      note "From Fragment Construction tasks the following #{fragment_from_construction_ids}"
      note "From metacol, the following #{fragment_from_metacol_ids}"
    }
    # Collect fragment info
    fragment_info_list = []
    not_ready = []

    io_hash[:fragment_ids].each do |fid|
      info = fragment_info fid
      fragment_info_list.push info   if info
      not_ready.push fid if !info
    end

    fragments       = fragment_info_list.collect { |fi| fi[:fragment] }
    templates       = fragment_info_list.collect { |fi| fi[:template] }
    forward_primers = fragment_info_list.collect { |fi| fi[:fwd] }
    reverse_primers = fragment_info_list.collect { |fi| fi[:rev] }
    temperatures    = fragment_info_list.collect { |fi| fi[:tanneal] }
    lengths         = fragment_info_list.collect { |fi| fi[:length] }

    if fragments.length == 0
      show {
        title "No fragments ready to build"
      }
      return { stripwell_ids: [] }
    end

    # find the average annealing temperature
    tanneal = temperatures.inject{ |sum, el| sum + el }.to_f / temperatures.size
    tanneal = 72 if tanneal > 72

    extension_time = (lengths.max)/1000.0*30
    mm, ss = (extension_time.to_i).divmod(60) 

    # Tell the user what we are doing
    show {
      title "Fragment Information"
      note "This protocol will build the following fragments:"
      note (fragments.collect { |f| "#{f}" })
      separator
      note "The following fragments have missing ingredients and will not be built:"
      note not_ready.to_s
    }

    # Take the primers and templates
    take templates + forward_primers + reverse_primers, interactive: true,  method: "boxes"

    # Get phusion enzyme
    phusion_stock_item = choose_sample "Phusion HF Master Mix", take: true

    # Set up stripwells
    stripwells = produce spread fragments, "Stripwell", 1, 12

    show {
      title "Prepare Stripwell Tubes"
      stripwells.each do |sw|
        check "Label a new stripwell with the id #{sw}."
        check "Pipette 19 µL of molecular grade water into wells " + sw.non_empty_string + "."
        separator
      end
      # TODO: Put an image of a labeled stripwell here
    }

    # Set up reactions
    load_samples( [ "Template, 1 µL", "Forward Primer, 2.5 µL", "Reverse Primer, 2.5 µL" ], [
        templates,
        forward_primers,
        reverse_primers
      ], stripwells ) {
        note "Load templates first, then forward primers, then reverse primers."
        warning "Use a fresh pipette tip for each transfer."
      }

    show {
      title "Add Master Mix"
      stripwells.each do |sw|
        check "Pipette 25 µL of master mix (item #{phusion_stock_item}) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
      end
      separator
      warning "USE A NEW PIPETTE TIP FOR EACH WELL AND PIPETTE UP AND DOWN TO MIX"
    }

    # Run the thermocycler
    thermocycler = show {
      title "Start the reactions"
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      separator
      check "Place the stripwells into an available thermal cycler and close the lid."
      get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
      separator
      check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'CLONEPCR'."
      check "Set the anneal temperature to #{tanneal.round(0)}. This is the 3rd temperature."
      check "Set the 4th time (extension time) to be #{mm}:#{ss}."
      check "Press 'run' and select 50 µL."
      # TODO: image: "thermal_cycler_home"
    }

    # Set the location of the stripwells to be the name of the thermocycler
    stripwells.each do |sw|
      sw.move thermocycler[:name]
    end

    # Release the templates, primers, and enzymes
    release templates + forward_primers + reverse_primers + [ phusion_stock_item ], interactive: true, method: "boxes" 

    # Release the stripwells silently, since they should stay in the thermocycler
    release stripwells

    io_hash[:stripwell_ids] = stripwells.collect { |s| s.id }

    return {io_hash: io_hash}

  end

end












