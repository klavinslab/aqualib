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

  def arguments
    {
      io_hash: {},
      "fragment_ids Fragment" => [2061,2062],
      debug_mode: "No",
      task_mode: "Yes",
      item_choice_mode: "No",
      group: "cloning"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { task_mode: "Yes", debug_mode: "No", item_choice_mode: "No", fragment_from_gibson_ids: [], fragment_from_construction_ids: [] }.merge io_hash # set default value of io_hash

    # redefine the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # Collect fragment info
    fragment_info_list = []
    not_ready = []

    io_hash[:fragment_ids].each do |fid|
      if io_hash[:item_choice_mode].downcase == "yes"
        info = fragment_info fid, item_choice: true
      else
        info = fragment_info fid
      end
      fragment_info_list.push info   if info
      not_ready.push fid if !info
    end

    all_fragments       = fragment_info_list.collect { |fi| fi[:fragment] }
    all_templates       = fragment_info_list.collect { |fi| fi[:template] }
    all_forward_primers = fragment_info_list.collect { |fi| fi[:fwd] }
    all_reverse_primers = fragment_info_list.collect { |fi| fi[:rev] }

    if all_fragments.length == 0
      show {
        title "No fragments ready to build"
      }
      io_hash[:stripwell_ids] = []
      return { io_hash: io_hash }
    end

    # Tell the user what we are doing
    show {
      title "Fragment Information"
      note "This protocol will build the following fragments:"
      note (all_fragments.collect { |f| "#{f}" })
      if not_ready.length > 0
        separator
        note "The following fragments have missing ingredients and will not be built:"
        note not_ready.to_s
      end
    }

    # Take the primers and templates
    take all_templates + all_forward_primers + all_reverse_primers, interactive: true,  method: "boxes"
    # Get phusion enzyme
    phusion_stock_item = choose_sample "Phusion HF Master Mix"

    take [phusion_stock_item], interactive: true, method: "boxes" 
    # Build a fragment_info_temp hash that group fragment info by T Anneal
    fragment_info_temp_hash = Hash.new {|h,k| h[k] = [] }
    fragment_info_list.each do |fi|
      if fi[:tanneal] >= 70
        fragment_info_temp_hash[70].push fi
      elsif fi[:tanneal] >= 67
        fragment_info_temp_hash[67].push fi
      else
        fragment_info_temp_hash[64].push fi
      end
    end

    all_stripwells = []

    fragment_info_temp_hash.each do |tanneal, fragment_info|
      lengths         = fragment_info.collect { |fi| fi[:length] }
      extension_time = (lengths.max)/1000.0*30 + 30
      mm, ss = (extension_time.to_i).divmod(60)

      # # find the average annealing temperature
      # tanneal = temperatures.inject{ |sum, el| sum + el }.to_f / temperatures.size
      # tanneal = 72 if tanneal > 72

      fragments       = fragment_info.collect { |fi| fi[:fragment] }
      templates       = fragment_info.collect { |fi| fi[:template] }
      forward_primers = fragment_info.collect { |fi| fi[:fwd] }
      reverse_primers = fragment_info.collect { |fi| fi[:rev] }

      # Set up stripwells
      stripwells = produce spread fragments, "Stripwell", 1, 12

      show {
        title "Prepare Stripwell Tubes"
        stripwells.each do |sw|
          if sw.num_samples <= 6
            check "Grab a new stripwell with 6 wells and label with the id #{sw}." 
          else
            check "Grab a new stripwell with 12 wells and label with the id #{sw}."
          end
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

      # Add phusion enzyme
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

      all_stripwells.concat stripwells
    end

    # Release phusion enzyme
    release [ phusion_stock_item ], interactive: true, method: "boxes" 
    # Release the templates, primers
    release all_templates + all_forward_primers + all_reverse_primers , interactive: true, method: "boxes" 

    # Release all stripwells silently, since they should stay in the thermocycler
    release all_stripwells
    
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"pcr")
      end
    end

    io_hash[:stripwell_ids] = all_stripwells.collect { |s| s.id }

    return { io_hash: io_hash }

  end

end












