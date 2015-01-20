# make yeast competent cells and freeze
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_culture_ids: [8429,8427],
      volumes: [100,100],
      large_volume: 50,
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

    io_hash = { yeast_competent_ids: [] }.merge io_hash
    if io_hash[:yeast_culture_ids].length == 0
      show {
        title "No competent cells need to be made"
        note "No competent cells need to be made. Thanks for you effort!"
      }
      return {io_hash: io_hash}
    end
    cultures = io_hash[:yeast_culture_ids].collect {|cid| find(:item, id:cid)[0]}
    take cultures, interactive: true

    num = cultures.length

    show{
      title "Prepare tubes"
      note "Label #{num} 1.5 mL tubes with #{(1..num).to_a}"
      note "Label #{num} 50 mL falcon tubes with #{(1..num).to_a}"     
    }

    show {
      title "Preperation another set of tubes"
      note "Label another set of #{num} 1.5 mL tubes with #{(1..num).to_a}"
      note "Label another set of #{num} 50 mL falcon tubes with #{(1..num).to_a}"
    } if io_hash[:large_volume] > 50
    
    show{
      title "Pour cells into 50 mL tubes"
      check "Pour all contents from the flask into the labeled 50 mL falcon tube according to the tabel below. Left over foams are OK."
      table [["Flask Label","50 mL Tube Number"]].concat(cultures.collect { |c| c.id } .zip (1..num).to_a) 
    }
    
    show{
      title "Centrifuge at 3000xg for 5 min"
      note "If you have never used the big centrifuge before, or are unsure about any aspect of what you have just done. ASK A MORE EXPERIENCED LAB MEMBER BEFORE YOU HIT START!"
      check "Balance the 50 mL tubes so that they all weigh approximately (within 0.1g) the same."
      check "Load the 50 mL tubes into the large table top centerfuge such that they are balanced."
      check "Set the speed to 3000xg" 
      check "Set the time to 5 minutes"
      warning "MAKE SURE EVERYTHING IS BALANCED"
      check "Hit start"
      
    }
    
    show{
      title "Pour out supernatant"
      check "After spin, take out 50 mL tubes and take them in a rack to the sink at the tube washing station without shaking tubes. Pour out liquid from tubes in one smooth motion so as not to disturb cell pellet then recap tubes and take back to bench."
    }
    
    show{
      title "Water washing"
      check "Add 1 mL of molecular grade water to each 50 mL tube and recap"
      check "Vortex the tubes till cell pellet is resuspended"
      check "Aliquot 1.5 mL from each 50 mL tube into the corresponding labeled 1.5 mL tube that has the same label number."
      note "It is OK if you have more than 1.5 mL of the resuspension. 1.5 mL is enough. If you have less than 1.5 mL, pipette as much as possible from tubes."
    }
    
    show{
      title "Water washing"
      check "Spin down all 1.5 mL tubes for 20 seconds or till cells are pelleted."
      check "Use a pipette and remove the supernatant from each tube without disturbing the cell pellet."
      check "Add 1 mL of molecular grade water to each 1.5 mL tube and recap."
      check "Vortex all tubes till cell pellet is resuspended"
      check "Spin down again for all tubes for 20 seconds or till cells are pelleted."
      check "Use a pipette and remove the supernatant from each tube without disturbing the cell pellet."
    }

    show {
      title "Prepare Frozen Competent Cell Solution (FCC Solution)"
      note "Take an existing FCC solution stock if there is one, if none, prepare with the following steps."
      check "Grab a 15 mL Falcon tube."
      check "Add 500 µL of DMSO, 500 µL of glyerol, 4 mL of molecular grade water."
      check "Mix by vortexing."
    }
    
    pellet_volume = show {
      title "Estimate pellet volume"
      check "Estimate the pellet volume using the gradations on the side of the eppendorf tube for each tube."
      note "The 0.1 on the tube means 100 µL and each line is another 100 µL."
      (1..num).each do |x|
        get "number", var: "#{x}_1", label: "Enter an estimated volume of the pellet for tube #{x}", default: 80
        get "number", var: "#{x}_2", label: "If you have another tube #{x}, enter an estimated volume of the pellet for another tube #{x}", default: 80 if io_hash[:large_volume] > 50
      end
    }

    show {
      title "Pipetting FCC into 1.5 mL tubes"
      (1..num).each do |x|
        check "Add #{4*pellet_volume[:"#{x}_1".to_sym]} µL of FCC to tube #{x}"
        check "Add #{4*pellet_volume[:"#{x}_2".to_sym]} µL of FCC to another tube #{x}" if io_hash[:large_volume] > 50
      end
      check "Vortex the tubes till cell pellet is resuspended"
    }

    volumes = []
    (1..num).each do |x|
      volume = 4.6*pellet_volume[:"#{x}_1".to_sym]
      volume += pellet_volume[:"#{x}_2".to_sym] if io_hash[:large_volume] > 50
      volumes.push volume
    end

    num_of_aliquots = volumes.collect {|v| (v/50.0).floor}

    yeast_compcell_aliquots = []
    cultures.each_with_index do |culture,idx|
      yeast_compcell_aliquots_temp = []
      (1..num_of_aliquots[idx]).each do |i|
        yeast_compcell_aliquot = produce new_sample culture.sample.name, of: "Yeast Strain", as: "Yeast Competent Aliquot"
        yeast_compcell_aliquots.push yeast_compcell_aliquot
        yeast_compcell_aliquots_temp.push yeast_compcell_aliquot
      end
      show {
        title "Aliquoting competent cells from 1.5 mL tube #{idx+1}"
        check "Label #{num_of_aliquots[idx]} empty 1.5 mL tubes with the following ids #{yeast_compcell_aliquots_temp.collect {|y| y.id}}"
        check "Add 50 µL from tube #{idx+1} to each newly labled tube"
      }
    end

    show {
      title "Discard and recycle tubes"
      note "Discard 1.5 mL tubes that was temporarily labeled with #{(1..cultures.length).to_a}."
      note "Recycle all 50 mL tubes by putting into a bin near the sink."
    }

    delete cultures

    show {
      title "Put into styrofoam holders in styrofoam box at M80"
      check "Place the 1.5mL tubes in styrofoam holders."
      check "Put into the styrofoam box and place in M80 for 10 minutes"
    }

    show {
      title "Wait and then retrive all 1.5 mL tubes from styrofoam box at M80"
      timer initial: { hours: 0, minutes: 10, seconds: 0}
      check "Retrive all 1.5 mL tubes from Styrofoam box at M80"
      note "Put back into M80 boxes according to the next release pages."
    }
    release yeast_compcell_aliquots, interactive: true, method: "boxes"
    io_hash[:yeast_competent_ids] = yeast_compcell_aliquots.collect {|y| y.id}
    
    return {io_hash: io_hash}
  end

end
