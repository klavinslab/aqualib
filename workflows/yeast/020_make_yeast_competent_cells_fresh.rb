# make fresh yeast competent cells and not freeze
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_culture_ids: [8429,8427],
      aliquot_numbers: [1,3],
      debug_mode: "Yes"
    }
  end

  def main

    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    l = choose_object "100 mM LiOAc"
    water = choose_object "50 mL Molecular Grade Water aliquot"
    take [l] + [water], interactive: true
    
    cultures = io_hash[:yeast_culture_ids].collect {|cid| find(:item, id:cid)[0]}
    take cultures, interactive: true
    
    culture_labels=[["Flask Label","50 mL Tube Number"]]
    cultures.each_with_index do |culture,idx|
      culture_labels.push([culture.id,idx+1])
    end
    
    show{
      title "Preperation Step"
      note "Label #{cultures.length} 1.5 mL tubes with #{(1..cultures.length).to_a}"
      note "Label #{cultures.length} 50 mL falcon tubes with #{(1..cultures.length).to_a}"
    }
    
    show{
      title "Harvesting Cells"
      check "Pour contents of flask into the labeled 50 mL falcon tube according to the tabel below"
      note "It does not matter if you dont get the foam into the tubes"
      table culture_labels
    }
    
    show{
      title "Harvesting Cells"
      check "Balance the 50 mL tubes so that they all weigh approximately (within 0.1g) the same."
      check "Load the 50 mL tubes into the large table top centerfuge such that they are balanced."
      check "Set the speed to 3000xg" 
      check "Set the time to 5 minutes"
      warning "MAKE SURE EVERYTHING IS BALANCED"
      check "Hit start"
      note "If you have never used the centerfuge before, or are unsure about any aspect of what you have just done ASK A MORE EXPERIENCED LAB MEMBER BEFORE YOU HIT START!"
    }
    
    show{
      title "Harvesting Cells"
      check "After spin take out 50 mL tubes and take them in a rack to the sink at the tube washing station without shaking tubes and pour out liquid from tubes in one smooth motion so as not to disturb cell pellet then recap tubes and take back to bench."
    }
    
    show{
      title "Making cells competent: Water wash"
      check "Add 1 mL of molecular grade water to each 50 mL tube and recap"
      check "Vortex the tubes till cell pellet is resuspended"
      check "Aliquot 1.5 mL from each 50 mL tube into the corresponding labeled 1.5 mL tube that has the same label number."
      note "It is OK if you have more than 1.5 mL of the resuspension. 1.5 mL is enough. If you have less than 1.5 mL, pipette as much as possible from tubes."
    }
    
    show{
      title "Making cells competent: LiAcO wash"
      check "Load the 1.5 mL tubes into the table top centerfuge and spin down for 20 seconds or till cells are pelleted"
      check "Use a pipette and remove the supernatant from each tube without disturbing the cell pellet."
      check  "Add 1 mL of 100 mM Lithium Acetate to each 1.5 mL tube and recap"
      check "Vortex the tubes till cell pellet is resuspended"
    }
    
    show{
      title "Making cells competent: Resuspension"
      check "Load the 1.5 mL tubes into the table top centerfuge and spin down for 20 seconds or till cells are pelleted"
      check "Use a pipette and remove the supernatant from each tube without disturbing the cell pellet."
    }
    
    show{
      title "Making cells competent: Resuspension"
      check "Estimate the pellet volume using the gradations on the side of the eppendorf tube for each tube."
      check "Add 4 times pellet volume of 100 mM Lithium Acetate to the 1.5 mL tube for each tube."
      check "Vortex the tubes till cell pellet is resuspended"
      note "The 0.1 on the tube means 100 µL and each line is another 100 µL"
    }

    yeast_compcell_aliquot_ids=[]
    cultures.each_with_index do |culture,idx|
      num = io_hash[:aliquot_numbers][idx]
      yeast_compcell_aliquots = []
      (1..num).each do |i|
        yeast_compcell_aliquot = produce new_sample culture.sample.name, of: "Yeast Strain", as: "Yeast Competent Aliquot"
        yeast_compcell_aliquots.push yeast_compcell_aliquot
        yeast_compcell_aliquot_ids.push yeast_compcell_aliquot.id
      end
      show {
        title "Aliquoting competent cells from 1.5 mL tube #{idx+1}"
        check "Label #{num} empty 1.5 mL tubes with the following ids #{yeast_compcell_aliquots.collect {|y| y.id}}"
        check "Add 50 µL from tube #{idx+1} to each newly labled tube"
      }
    end

    show {
      title "Discard and recycle tubes"
      note "Discard 1.5 mL tubes that was temporarily labeled with #{(1..cultures.length).to_a}."
      note "Recycle all 50 mL tubes by putting into a bin near the sink."
    }

    cultures.each do |y|
      y.mark_as_deleted
      y.save
    end

    release [l] + [water] + cultures, interactive: true

    io_hash[:yeast_competent_ids] = yeast_compcell_aliquot_ids
    
    return {io_hash: io_hash}
  end

end
