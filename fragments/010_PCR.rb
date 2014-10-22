needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def debug
    false
  end

  def arguments
    {
      # For testing purposes, choose a random set of 10 fragments
      "fragment_ids Fragment" => [0]
    }
  end

  def main

    # Collect fragment info
    fragment_info_list = []
    not_ready = []

    input[:fragment_ids].each do |fid|
      info = fragment_info fid
      fragment_info_list.push info   if info
      not_ready.push fid if !info
    end

    fragments       = fragment_info_list.collect { |fi| fi[:fragment] }
    templates       = fragment_info_list.collect { |fi| fi[:template] }
    forward_primers = fragment_info_list.collect { |fi| fi[:fwd] }
    reverse_primers = fragment_info_list.collect { |fi| fi[:rev] }
    temperatures    = fragment_info_list.collect { |fi| fi[:tanneal] }

    if fragments.length == 0
      show {
        title "No fragments ready to build"
      }
      return { stripwell_ids: [] }
    end

    # find the average annealing temperature
    tanneal = temperatures.inject{ |sum, el| sum + el }.to_f / temperatures.size

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
    phusion_stock_item = choose_sample "Phusion HF Master Mix"

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
      check "Click 'Home' then click 'Saved Protocol'. Choose 'DAVID' and then 'CLONEPCR'."
      check "Set the anneal temperature to #{tanneal}. This is the 3rd temperature (default 70). Don't change the extension temperature of 72."
      check "Press 'run' and select 50ul."
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

    return { stripwell_ids: stripwells.collect { |s| s.id } }

  end

end












