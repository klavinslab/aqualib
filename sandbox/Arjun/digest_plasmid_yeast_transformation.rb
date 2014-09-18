needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      plasmid_ids: []
    }
  end
  
  def main
    
    plasmids_to_take = find(:item, id: input[:plasmid_ids].uniq )
    plasmids_to_digest = find(:item, id: input[:plasmid_ids] )
    
    show {
      table [ plasmids_to_digest.collect { |x| x.id } ]
    }
    
    take plasmids_to_take, interactive: true
    
    cut_smart= choose_sample "Cut Smart"
    
    digestions=[]
    
    plasmids_to_digest.each do |plasmid|
        
        j = produce new_sample plasmid.sample.name, of: "Plasmid", as: "Digested Plasmid"
        digestions.push(j)
        
    end    
    
    
    stripwells = produce spread digestions, "Stripwell", 1, 12
    
    
    
    show {
      warning "In the following step you will take PMEI enzyme out of the freezer. Make sure the enzyme is kept on ice for the duration of the protocol."
    }
    
    pme1= choose_sample "PmeI"
    
    water = 42*plasmids_to_digest.length*1.3
    buffer = 5*plasmids_to_digest.length*1.3
    enzyme = 1*plasmids_to_digest.length*1.3
    
    show {
      title "Make master mix"
      check "Label a new eppendorf tube MM."
      check "Add #{water}ul of water to the tube"
      check "Add #{buffer}ul of the cutsmart buffer to the tube"
      check "Add #{enzyme}ul of the Pme1 to the tube"
      check "Vortex for 20-30 seconds"
      warning "Keep the master mix in an ice block while doing the next steps"
    }
    
    release [pme1]
    release [cut_smart]
    
    show {
      title "Prepare Stripwell Tubes"
      stripwells.each do |sw|
        check "Label a new stripwell with the id #{sw}."
        check "Pipette 48 µL of MM made in previous step into wells"
      end
    }
    
    load_samples( ["Plasmid, 2 µL"], [plasmids_to_digest], stripwells ) {
      note "Add 2ul of each plasmid into the stripwell indicated."
      warning "Use a fresh pipette tip for each transfer."
    }
    
    thermocycler = show {
      title "Start the reactions"
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      separator
      check "Place the stripwells into an available thermal cycler and close the lid."
      get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
      separator
      check "Click 'Home' then click 'Saved Protocol'. Choose 'Digestion'."
      check "Press 'run' and select 50ul."
      # TODO: image: "thermal_cycler_home"
    }
    
    stripwells.each do |sw|
      sw.move thermocycler[:name]
    end
    
    release stripwells

    return { stripwell_ids: stripwells.collect { |s| s.id } }
    
    
  end
  
end
