needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #stripwell that containing digested plasmids
      "stripwell_ids Stripwell" => [27109],
      "yeast_transformed_strain_ids Yeast Strain" => [1705,1706,5079,5079],
      task_ids: [8466,8467,8468],
      debug_mode: "Yes"
    }
  end

  def update_batch_matrix batch, num_samples, plate_type
    rows = batch.matrix.length
    columns = batch.matrix[0].length
    batch.matrix = fill_array rows, columns, num_samples, find(:sample, name: "#{plate_type}")[0].id
    batch.save
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", plasmid_ids: [], task_ids: [], yeast_transformed_strain_ids: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    if io_hash[:yeast_transformed_strain_ids].length == 0
      show {
        title "No yeast transformation required"
        note "No yeast transformation need to be done. Thanks for your effort!"
      }
      return { io_hash: io_hash }
    end

    io_hash[:yeast_parent_strain_ids] = io_hash[:yeast_transformed_strain_ids].collect { |yid| find(:sample, id: yid)[0].properties["Parent"].id }

    # parse out a list of plasmid sample ids from stripwels
    stripwells = io_hash[:stripwell_ids].collect { |i| collection_from i }
    stripwells_array = stripwells.collect { |s| s.matrix }
    io_hash[:plasmid_ids] = stripwells_array.flatten
    io_hash[:plasmid_ids].delete(-1)

    yeast_competent_cells = []
    yeast_competent_cells_full = [] # an array of yeast_competent_cells include nils.
    no_comp_cell_strain_ids = []
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
        no_comp_cell_strain_ids.push io_hash[:yeast_transformed_strain_ids][idx]
        io_hash[:yeast_transformed_strain_ids][idx] = nil
        io_hash[:plasmid_ids][idx] = nil
      end

    end

    io_hash[:yeast_transformed_strain_ids].compact!
    io_hash[:plasmid_ids].compact!

    if no_comp_cell_strain_ids.blank?
      show {
        title "Some transformations can not be done"
        note "Transformation for the following yeast strain can not be performed since there is not enough competent cell."
        note no_comp_cell_strain_ids
      }
    end

    if yeast_competent_cells.blank?
      show {
        title "No yeast transformation required"
        note "No yeast transformation need to be done. Thanks for your effort!"
      }
    else
      take yeast_competent_cells, interactive: true, method: "boxes"

      yeast_transformation_mixtures = io_hash[:yeast_transformed_strain_ids].collect {|yid| produce new_sample find(:sample, id: yid)[0].name, of: "Yeast Strain", as: "Yeast Transformation Mixture"}

      # show {
      #   title "Testing page"
      #   note(yeast_competent_cells.collect {|x| x.id})
      #   note(yeast_transformation_mixtures.collect {|x| x.id})
      # }

      peg = find(:item, object_type: { name: "50 percent PEG 3350" })[-1]
      lioac = find(:item, object_type: { name: "1.0 M LiOAc" })[-1]
      ssDNA = find(:item, object_type: { name: "Salmon Sperm DNA (boiled)" })[-1]
      reagents = [peg] + [lioac] + [ssDNA]
      take reagents, interactive: true

      tab = [["Old id","New id"]]
      yeast_competent_cells.each_with_index do |y,idx|
        tab.push([y.id,yeast_transformation_mixtures[idx].id])
      end

      take stripwells, interactive: true

      show {
        title "Yeast transformation preparation"
        check "Spin down all the Yeast Competent Aliquots on table top centrifuge for 20 seconds"
        check "Add 240 µL of 50 percent PEG 3350 into each competent aliquot tube."
        warning "Be careful when pipetting PEG as it is very viscous. Pipette slowly"
        check "Add 36 µL of 1M LiOAc to each tube"
        check "Add 25 µL of Salmon Sperm DNA (boiled) to each tube"
        warning "The order of reagents added is super important for suceess of transformation."
      }

      load_samples_variable_vol(["Yeast Competent Aliquot"],[yeast_competent_cells_full], stripwells) {
        title "Load 50 µL from each well into corresponding yeast aliquot"
        note "Pipette 50 µL from each well into corresponding yeast aliquot"
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
        check "Vortex each tube on highest settings until the cells are resuspended."
        check "Place all aliquots on 42 C heat block for 15 minutes."
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
      overall_batches = find(:item, object_type: { name: "Agar Plate Batch" }).map{|b| collection_from b}
      
      plate_batch_ids = Array.new

      yeast_transformation_mixtures_markers.each do |key, mixtures|
        if ["nat","kan","hyg","ble"].include? key
          mixtures_to_incubate.concat mixtures
        else
          yeast_plates_sub = mixtures.collect {|v| produce new_sample v.sample.name, of: "Yeast Strain", as: "Yeast Plate"}
          yeast_plates.concat yeast_plates_sub
          mixtures_to_plate.concat mixtures
          if key == "foa"
            grab_plate_tab.push(["5-#{key.upcase}", yeast_plates_sub.length, yeast_plates_sub.collect { |y| y.id }.join(", ")])
          else
            grab_plate_tab.push(["-#{key.upcase}", yeast_plates_sub.length, yeast_plates_sub.collect { |y| y.id }.join(", ")])
            plate_batch = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0].name == "SDO -#{key.capitalize}" }
            plate_batch_id = "none" 
            num = yeast_plates_sub.length
            if plate_batch.present?
              plate_batch_id = "#{plate_batch.id}"
              num_plates = plate_batch.num_samples
              update_batch_matrix plate_batch, num_plates - num, "SDO -#{key.capitalize}"
              if num_plates == num
                plate_batch.mark_as_deleted
              end
              if num_plates < num 
                num_left = num - num_plates
                plate_batch_two = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0].name == "SDO -#{key.capitalize}" }
                update_batch_matrix plate_batch_two, plate_batch_two.num_samples - num_left, "SDO -#{key.capitalize}" if plate_batch_two.present?
                plate_batch_id = plate_batch_id + ", #{plate_batch_two.id}" if plate_batch_two.present?
              end
            end
            plate_batch_ids.push(plate_batch_id)
          end
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
          note "Grab the following plates from batches #{plate_batch_ids.join(", ")} and label with your initials, the date, and the following ids on the top and side of each plate."
          table grab_plate_tab
        }
        show {
          title "Resuspend in water and plate"
          check "Add 200 µL of MG water to the following mixtures shown in the table and resuspend."
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
        
        show {
          title "Move antibiotic plates to the media fridge (if applicable)"
          warning "If any antibiotic plates were made, label the foil TOXIC with red sharpie, and move them to the side of the door in the media fridge."
        }

        delete mixtures_to_plate
        move yeast_plates, "30 C incubator"
        release yeast_plates, interactive: true

      end

      delete yeast_competent_cells
      release reagents, interactive: true
      io_hash[:plate_ids]= yeast_plates.collect {|x| x.id} if yeast_plates.length > 0
      io_hash[:yeast_transformation_mixture_ids] = mixtures_to_incubate.collect { |y| y.id }
    end

    not_done_task_ids = []
    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      yeast_transformed_strain_ids = task.simple_spec[:yeast_transformed_strain_ids]
      not_transformed_ids = yeast_transformed_strain_ids & no_comp_cell_strain_ids
      if [not_transformed_ids].any?
        not_transformed_ids_link = not_transformed_ids.collect { |id| item_or_sample_html_link id, :sample }.join(", ")
        task.notify "#{'Yeast Strain'.pluralize(not_transformed_ids.length)} #{not_transformed_ids_link} can not be transformed due to not enough competent cells.", job_id: jid
      end
      if not_transformed_ids == yeast_transformed_strain_ids
        not_done_task_ids.push tid
        set_task_status(task,"waiting")
        task.notify "Pushed back to waiting due to not enough competent cells.", job_id: jid
      else
        set_task_status(task,"transformed")
      end
    end
    io_hash[:task_ids] = io_hash[:task_ids] - not_done_task_ids

    return { io_hash: io_hash }

  end

end
