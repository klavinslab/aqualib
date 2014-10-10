needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      io_hash: {},
      plasmid_ids: [27507,27508,27509]
    }
  end
  
  def main

    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    plasmids_to_digest = io_hash[:plasmid_ids].collect{|pid| find(:item, id: pid )[0]}
    plasmids_to_take = plasmids_to_digest.uniq


    take plasmids_to_take, interactive: true, method: "boxes"
    
    cut_smart= choose_sample "Cut Smart"
    take [cut_smart], interactive: true, method: "boxes"
    
    digestions=[]
    
    plasmids_to_digest.each do |plasmid|
        
        j = produce new_sample plasmid.sample.name, of: "Plasmid", as: "Digested Plasmid"
        digestions.push(j)
        
    end    
    
    
    stripwells = produce spread digestions, "Stripwell", 1, 12

    show {
      warning "In the following step you will take PmeI enzyme out of the freezer. Make sure the enzyme is kept on ice for the duration of the protocol."
    }
    
    pme1= choose_sample "PmeI"
    take [pme1], interactive: true, method: "boxes"
    
    water = 42*plasmids_to_digest.length*1.3
    buffer = 5*plasmids_to_digest.length*1.3
    enzyme = 1*plasmids_to_digest.length*1.3
    
    show {
      title "Make master mix"
      check "Label a new eppendorf tube MM."
      check "Add #{water.round(1)} µL of water to the tube"
      check "Add #{buffer.round(1)} µL of the cutsmart buffer to the tube"
      check "Add #{enzyme.round(1)} µL of the Pme1 to the tube"
      check "Vortex for 20-30 seconds"
      warning "Keep the master mix in an ice block while doing the next steps"
    }
    
    release [pme1] + [cut_smart], interactive: true, method: "boxes"
    
    show {
      title "Prepare Stripwell Tubes"
      stripwells.each do |sw|
        check "Label a new stripwell with the id #{sw}. Just use a full size stripwell."
        check "Pipette 48 µL of MM made in previous step into wells" + sw.non_empty_string + "."
        separator
      end
    }
    
    load_samples( ["Plasmid, 2 µL"], [plasmids_to_digest], stripwells ) {
      note "Add 2 µL of each plasmid into the stripwell indicated."
      warning "Use a fresh pipette tip for each transfer."
    }
    
    incubate = show {
      title "Start the reactions"
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      separator
      check "Place the stripwells into a small green tube holder and then place in 37 C incubator at B15.320."
      # TODO: image: "thermal_cycler_home"
    }
    
    stripwells.each do |sw|
      sw.move "37 C incubator at B15.320"
    end
    
    release stripwells
    release plasmids_to_take, interactive: true, method: "boxes"

    io_hash[:stripwell_ids] = stripwells.collect { |s| s.id }
    return { io_hash: io_hash }
    
  end
  
end
