# make yeast competent cells from yeast 50 mL culture and freeze
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_culture_ids: [34887,34888],
      overnight_ids: [34883,34884,34885],
      debug_mode: "Yes"
    }
  end

  def main

    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?

    io_hash = { falcon_tube_size: 14, yeast_culture_ids: [], overnight_ids: [], volume: 2 }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    io_hash[:falcon_tube_size] = 50 if io_hash[:yeast_culture_ids].length > 0

    io_hash = { yeast_competent_cell_ids: [] }.merge io_hash

    if io_hash[:yeast_culture_ids].length == 0 && io_hash[:overnight_ids].length > 0 && io_hash[:volume] >= 4
      io_hash[:yeast_culture_ids] = io_hash[:overnight_ids]
    end

    if io_hash[:yeast_culture_ids].length == 0
      show {
        title "No competent cells need to be made"
        note "No competent cells need to be made. Thanks for you effort!"
      }
      return { io_hash: io_hash }
    end

    cultures = io_hash[:yeast_culture_ids].collect { |cid| find(:item, id:cid)[0] }
    take cultures, interactive: true

    num = cultures.length

    show{
      title "Prepare tubes"
      note "Label #{num} 1.5 mL tubes with #{(1..num).to_a}"
      note "Label #{num} #{io_hash[:falcon_tube_size]} mL falcon tubes with #{(1..num).to_a}"
    }

    show{
      title "Pour cells into #{io_hash[:falcon_tube_size]} mL tubes"
      check "Pour all contents from the flask into the labeled #{io_hash[:falcon_tube_size]} mL falcon tube according to the tabel below. Left over foams are OK."
      table [["Flask Label","#{io_hash[:falcon_tube_size]} mL Tube Number"]].concat(cultures.collect { |c| { content: c.id, check: true } } .zip (1..num).to_a)
    }
    
    show{
      title "Centrifuge at 3000xg for 5 min"
      note "If you have never used the big centrifuge before, or are unsure about any aspect of what you have just done. ASK A MORE EXPERIENCED LAB MEMBER BEFORE YOU HIT START!"
      check "Balance the #{io_hash[:falcon_tube_size]} mL tubes so that they all weigh approximately (within 0.1g) the same."
      check "Load the #{io_hash[:falcon_tube_size]} mL tubes into the large table top centerfuge such that they are balanced."
      check "Set the speed to 3000xg." 
      check "Set the time to 5 minutes."
      warning "MAKE SURE EVERYTHING IS BALANCED"
      check "Hit start"
      
    }
    
    show {
      title "Pour out supernatant"
      check "After spin, take out all #{io_hash[:falcon_tube_size]} mL falcon tubes and place them in a rack."
      check "Take to the sink at the tube washing station without shaking tubes. Pour out liquid from tubes in one smooth motion so as not to disturb cell pellet."
      check "Recap tubes and take back to the bench."
    }
    
    show {
      title "Water washing in #{io_hash[:falcon_tube_size]} mL tube"
      check "Add 1 mL of molecular grade water to each #{io_hash[:falcon_tube_size]} mL tube and recap."
      check "Vortex the tubes till cell pellet is resuspended."
      check "Aliquot 1.5 mL from each #{io_hash[:falcon_tube_size]} mL tube into the corresponding labeled 1.5 mL tube that has the same label number."
      note "It is OK if you have more than 1.5 mL of the resuspension. 1.5 mL is enough. If you have less than 1.5 mL, pipette as much as possible from tubes."
    }
    
    show {
      title "Water washing in 1.5 mL tube"
      check "Spin down all 1.5 mL tubes for 20 seconds or till cells are pelleted."
      check "Use a pipette and remove the supernatant from each tube without disturbing the cell pellet."
      check "Add 1 mL of molecular grade water to each 1.5 mL tube and recap."
      check "Vortex all tubes till cell pellet is resuspended."
      check "Spin down all 1.5 mL tubes again for 20 seconds or till cells are pelleted."
      check "Use a pipette to remove the supernatant from each tube without disturbing the cell pellet."
    }

    show {
      title "Prepare FCC Solution"
      note "Take an existing FCC (Frozen Competent Cell) solution stock if there is one, if none, prepare with the following steps."
      check "Grab a 15 mL Falcon tube."
      check "Add 500 µL of DMSO, 500 µL of glyerol, 4 mL of molecular grade water."
      check "Mix by vortexing."
    }

    # ask the user to estimate the pellet volume
    pellet_volume = show {
      title "Estimate pellet volume"
      check "Estimate the pellet volume using the gradations on the side of the 1.5 mL tube."
      note "The 0.1 on the tube means 100 µL and each line is another 100 µL. Noting that normally the pellet volume should be greater than 0 µL and less than 500 µL. Enter a number between 0 to 500."
      (1..num).each do |x|
        get "number", var: "#{x}", label: "Enter an estimated volume in µL of the pellet for tube #{x}", default: 80
      end
    }

    # ask the user to enter again if the pellet_volume is too large or too small.
    (1..num).each do |x|
      while pellet_volume[:"#{x}".to_sym] > 500 || pellet_volume[:"#{x}".to_sym] < 0
        re_pellet_volume = show {
          title "Re-estimate the pellet volume"
          note "Are you really sure you pellet volume for tube #{x} is #{pellet_volume[:"#{x}".to_sym]} µL? Noting that pellet volume means the spun down pellet volume. Did you spin down your tube?"
          note "Enter a number between 0 to 500."
          get "number",  var: "#{x}", label: "Re-enter an estimated volume in µL of the pellet for tube #{x}", default: 80
        }
        pellet_volume[:"#{x}".to_sym] = re_pellet_volume[:"#{x}".to_sym]
      end
    end

    show {
      title "Pipetting FCC into 1.5 mL tubes"
      (1..num).each do |x|
        check "Add #{4 * pellet_volume[:"#{x}".to_sym]} µL of FCC to tube #{x}, use additional tubes if needed."
      end
      check "Vortex the tubes till cell pellet is resuspended."
    }

    # calculate the total volumes with a margin, instead of 5 times pellet_volume, use 4.6 times pellet_volume
    volumes = []
    (1..num).each do |x|
      volume = 4.6 * pellet_volume[:"#{x}".to_sym]
      volumes.push volume
    end

    num_of_aliquots = volumes.collect {|v| (v / 50.0).floor}

    yeast_compcell_aliquots = []
    cultures.each_with_index do |culture,idx|
      yeast_compcell_aliquots_temp = []
      (1..num_of_aliquots[idx]).each do |i|
        yeast_compcell_aliquot = produce new_sample culture.sample.name, of: "Yeast Strain", as: "Yeast Competent Cell"
        yeast_compcell_aliquots.push yeast_compcell_aliquot
        yeast_compcell_aliquots_temp.push yeast_compcell_aliquot
      end
      show {
        title "Aliquoting competent cells from 1.5 mL tube #{idx+1}"
        check "Label #{num_of_aliquots[idx]} empty 1.5 mL tubes with the following ids #{yeast_compcell_aliquots_temp.collect {|y| y.id}}."
        check "Add 50 µL from tube #{idx+1} to each newly labled tube."
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
      check "Place the aliquoted 1.5 mL tubes in styrofoam holders."
      check "Put into the styrofoam box and place in M80 for 10 minutes"
    }

    show {
      title "Wait and then retrive all aliquoted 1.5 mL tubes"
      timer initial: { hours: 0, minutes: 10, seconds: 0}
      check "Retrive all aliquoted 1.5 mL tubes from the styrofoam box at M80."
      note "Put back into M80C boxes according to the next release pages."
    }

    release yeast_compcell_aliquots, interactive: true, method: "boxes"
    io_hash[:yeast_competent_cell_ids] = yeast_compcell_aliquots.collect {|y| y.id}

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        if task.task_prototype.name == "Yeast Competent Cell"
          set_task_status(task,"done")
        end
      end
    end

    return { io_hash: io_hash }

  end

end
