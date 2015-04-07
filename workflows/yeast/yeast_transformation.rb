needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_parent_strain_ids: [30,30,30,30],
      #stripwell that containing digested plasmids
      "stripwell_ids Stripwell" => [27109],
      "yeast_transformed_strain_ids Yeast Strain" => [1705,1706,5079,5079],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", plasmid_ids: [] }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    if io_hash[:yeast_parent_strain_ids].length == 0
      show {
        title "No yeast transformation required"
        note "No yeast transformation need to be done. Thanks for your effort!"
      }
      return { io_hash: io_hash }
    end

    # parse out a list of plasmid sample ids from stripwels
    stripwells = io_hash[:stripwell_ids].collect { |i| collection_from i }
    stripwells_array = stripwells.collect { |s| s.matrix }
    io_hash[:plasmid_ids] = stripwells_array.flatten
    io_hash[:plasmid_ids].delete(-1)

    yeast_competent_cells = []
    yeast_competent_cells_full = [] # an array of yeast_competent_cells include nils.
    no_competent_cell_yeast_transformed_strain_ids = []
    aliquot_num_hash = Hash.new {|h,k| h[k] = 0 }
    cell_num_hash = Hash.new {|h,k| h[k] = 0 }
    io_hash[:yeast_parent_strain_ids].each_with_index do |yid, idx|
      y = find(:sample, id: yid )[0]
      aliquot_num_hash[y.name] += 1
      if y.in("Yeast Competent Aliquot")[ aliquot_num_hash[y.name] - 1 ]
        competent_cell = y.in("Yeast Competent Aliquot")[ aliquot_num_hash[y.name] - 1 ]
      else
        cell_num_hash[y.name] += 1
        competent_cell = y.in("Yeast Competent Cell")[ cell_num_hash[y.name] - 1 ]
      end

      if competent_cell
        yeast_competent_cells.push competent_cell
        yeast_competent_cells_full.push competent_cell.id
      else
        yeast_competent_cells_full.push "NA"
        no_competent_cell_yeast_transformed_strain_ids.push io_hash[:yeast_transformed_strain_ids][idx]
        io_hash[:yeast_transformed_strain_ids][idx] = nil
        io_hash[:plasmid_ids][idx] = nil
      end

    end

    io_hash[:yeast_transformed_strain_ids].compact!
    io_hash[:plasmid_ids].compact!

    if no_competent_cell_yeast_transformed_strain_ids.length > 0
      show {
        title "Some transformations can not be done"
        note "Transformation for the following yeast strain can not be performed since there is not enough competent cell."
        note no_competent_cell_yeast_transformed_strain_ids
      }
    end

    if yeast_competent_cells.length == 0
      show {
        title "No yeast transformation required"
        note "No yeast transformation need to be done. Thanks for your effort!"
      }
      return { io_hash: io_hash }
    end

    take yeast_competent_cells, interactive: true, method: "boxes"

    yeast_transformation_mixtures = io_hash[:yeast_transformed_strain_ids].collect {|yid| produce new_sample find(:sample, id: yid)[0].name, of: "Yeast Strain", as: "Yeast Transformation Mixture"}

    # show {
    #   title "Testing page"
    #   note(yeast_competent_cells.collect {|x| x.id})
    #   note(yeast_transformation_mixtures.collect {|x| x.id})
    # }

    peg = choose_object "50 percent PEG 3350"
    lioac = choose_object "1.0 M LiOAc"
    ssDNA = choose_object "Salmon Sperm DNA (boiled)"
    take [peg] + [lioac] + [ssDNA], interactive: true

    tab = [["Old id","New id"]]
    yeast_competent_cells.each_with_index do |y,idx|
      tab.push([y.id,yeast_transformation_mixtures[idx].id])
    end

    take stripwells, interactive: true

    show {
      title "Yeast transformation preparation"
      check "Spin down all the Yeast Competent Aliquots on table top centrifuge for 20 seconds"
      check "Add 240 µL of 50 percent PEG 3350 into each competent aliquot tube."
      warning "Be careful when pipetting PEG as it is very viscus. Pipette slowly"
      check "Add 36 µL of 1M LiOAc to each tube"
      check "Add 25 µL of Salmon Sperm DNA (boiled) to each tube"
      warning "The order of reagents added is super important for suceess of transformation."
    }

    load_samples_variable_vol(["Yeast Competent Aliquot"],[yeast_competent_cells_full], stripwells) {
      title "Load 50 µL from each well into corresponding yeast aliquot"
      note "Pieptte 50 µL from each well into corresponding yeast aliquot"
      note "Discard the stripwell into waste bin."
    }

    show {
      title "Re-label all the competent cell tubes"
      table [["Old id","New id"]].concat(yeast_competent_cells.collect {|y| y.id }.zip yeast_transformation_mixtures.collect { |y| { content: y.id, check: true } })
    }

    stripwells.each do |stripwell|
        stripwell.mark_as_deleted
    end

    show {
      title "Vortex strongly and heat shock"
      check "Vortex each tube on highest settings for 45 seconds"
      check "Place all aliquots on 42 C heat block for 15 minutes"
    }

    show {
      title "Retrive tubes and spin down"
      timer initial: { hours: 0, minutes: 15, seconds: 0}
      check "Retrive all #{yeast_transformation_mixtures.length} tubes from 42 C heat block."
      check "Spin the tube down for 20 seconds on a small tabletop centrifuge."
      check "Remove all the supernatant carefully with a 1000 µL pipettor (~400 µL total)"
    }

    yeast_markers = io_hash[:plasmid_ids].collect {|pid| find(:sample, id: pid )[0].properties["Yeast Marker"].downcase[0,3]}
    yeast_transformation_mixtures_markers = Hash.new {|h,k| h[k] = [] }
    yeast_transformation_mixtures.each_with_index do |y,idx|
      yeast_markers.uniq.each do |mk|
        yeast_transformation_mixtures_markers[mk].push y if yeast_markers[idx] == mk
      end
    end

    mixtures_to_incubate = []
    mixtures_to_plate = []
    yeast_plates = []

    grab_plate_tab = [["Plate type","Quantity","Id to label"]]
    plating_info_tab = [["1.5 mL tube id","Plate id"]]

    yeast_transformation_mixtures_markers.each do |key, mixtures|
      if ["nat","kan","hyg","ble"].include? key
        mixtures_to_incubate.concat mixtures
      else
        yeast_plates_sub = mixtures.collect {|v| produce new_sample v.sample.name, of: "Yeast Strain", as: "Yeast Plate"}
        yeast_plates.concat yeast_plates_sub
        mixtures_to_plate.concat mixtures

        grab_plate_tab.push(["-#{key.upcase}", yeast_plates_sub.length, yeast_plates_sub.collect { |y| y.id }.join(", ")])
        mixtures.each_with_index do |y,idx|
          plating_info_tab.push([y.id, yeast_plates_sub[idx].id])
        end
      end
    end

    if mixtures_to_incubate.length > 0
      show {
        title "Resuspend in YPAD and incubate"
        check "Grab #{"tube".pluralize(mixtures_to_incubate.length)} with id #{(mixtures_to_incubate.collect {|x| x.id}).join(", ")}"
        check "Add 1 mL of YPAD to the each tube and vortex for 20 seconds"
        check "Grab #{mixtures_to_incubate.length} 14 mL #{"tube".pluralize(mixtures_to_incubate.length)}, label with #{(mixtures_to_incubate.collect {|x| x.id}).join(", ")}"
        check "Transfer all contents from each 1.5 mL tube to corresponding 14 mL tube that has the same label number"
        check "Place all #{mixtures_to_incubate.length} 14 mL #{"tube".pluralize(mixtures_to_incubate.length)} into 30 C shaker incubator"
        check "Discard all #{mixtures_to_incubate.length} empty 1.5 mL #{"tube".pluralize(mixtures_to_incubate.length)} "
      }
      mixtures_to_incubate.each do |y|
        y.location = "30 C shaker incubator"
        y.save
      end
      release mixtures_to_incubate
    end

    if mixtures_to_plate.length > 0
      show {
        title "Grab plate"
        note "Grab the following plates and label with ids."
        table grab_plate_tab
      }
      show {
        title "Resuspend in water and plate"
        check "Add 200 µL of MG water to the following mixtures shown in the table."
        check "Flip the plate and add 4-5 glass beads to it, add 200 µL of mixtures on each plate."
        table plating_info_tab
      }

      show {
        title "Shake and incubate"
        check "Shake the plates in all directions to evenly spread the culture over its surface till dry."
        check "Discard the beads in a used beads container."
        check "Throw away the following 1.5 mL tubes."
        note mixtures_to_plate.collect { |x| "#{x}"}
        check "Incubate all the plates with agar side up shown in the next page."
      }

      delete mixtures_to_plate
      move yeast_plates, "30 C incubator"
      release yeast_plates, interactive: true

    end

    delete yeast_competent_cells

    release [peg] + [lioac] + [ssDNA], interactive: true

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"transformed")
      end
    end
    io_hash[:plate_ids]= yeast_plates.collect {|x| x.id} if yeast_plates.length > 0

    io_hash[:yeast_transformation_mixture_ids] = mixtures_to_incubate.collect { |y| y.id }
    
    return { io_hash: io_hash }

  end

end
