needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def update_batch_matrix batch, num_samples, plate_type
    rows = batch.matrix.length
    columns = batch.matrix[0].length
    batch.matrix = fill_array rows, columns, num_samples, find(:sample, name: "#{plate_type}")[0].id
    batch.save
  end # update_batch_matrix

  def arguments
    {
      io_hash: {},
      transformed_aliquots_ids: [9191,9190,8418],
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?

    io_hash = { plate_ids: [], debug_mode: "no" }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    all_transformed_aliquots = io_hash[:transformed_aliquots_ids].collect { |tid| find(:item, id: tid)[0] }
    if all_transformed_aliquots.length == 0
      show {
        title "No plating required"
        note "No transformed aliquots need to be plated. Thanks for your effort!"
      }
    end

    take all_transformed_aliquots, interactive: true if all_transformed_aliquots.length > 0

    all_plates = all_transformed_aliquots.collect { |t| produce new_sample t.sample.name, of: "Plasmid", as: "E coli Plate of Plasmid" }
    all_plates.each_with_index do |all_plate,idx|
    all_plate.datum = all_plate.datum.merge({ from: all_transformed_aliquots[idx].id })
    end

    plates_marker_hash = Hash.new { |h,k| h[k] = [] }
    all_plates.each do |p|
      marker_key = "LB"
      p.sample.properties["Bacterial Marker"].split(',').each do |marker|
        marker_key = marker_key + " + " + formalize_marker_name(marker)
      end
      plates_marker_hash[marker_key].push p
    end

    deleted_plates = []
    plates_marker_hash.each do |marker, plates|
      transformed_aliquots = plates.collect { |p| all_transformed_aliquots[all_plates.index(p)] }
      unless marker == "LB"
        marker = "chlor" if marker == "chl"
        plates_with_initials = plates.collect {|x| "#{x.id} "+ name_initials(x.sample.user.name)}
        num = plates.length
        plate_type = "#{marker}"
        overall_batches = find(:item, object_type: { name: "Agar Plate Batch" }).map{|b| collection_from b}
        plate_batch = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0].name == plate_type}
        plate_batch_id = "none" 
        if plate_batch.present?
            plate_batch_id = "#{plate_batch.id}"
            num_plates = plate_batch.num_samples
            update_batch_matrix plate_batch, num_plates - num, plate_type
            if num_plates < num 
              num_left = num - num_plates
              plate_batch_two = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0].name == plate_type }
              update_batch_matrix plate_batch_two, plate_batch_two.num_samples - num_left, plate_type if plate_batch_two.present?
              plate_batch_id = plate_batch_id + ", #{plate_batch_two.id}" if plate_batch_two.present?
            end
        end
        show {
          title "Grab #{num} #{"plate".pluralize(num)}"
          check "Grab #{num} #{plate_type} Plate (sterile) from batch #{plate_batch_id}"
          check "Label the top of the plates with your intials, the date, and the following ids #{plates_with_initials}"
          check "Label the side of the plates with the same id number as on top"
        }
        show {
          title "Plating"
          check "Use sterile beads to plate THE ENTIRE VOLUME (300 uL) from transformed aliquots (1.5 mL tubes) on to the plates following the table below."
          warning "Note the change in plating volume!"
          check "Discard used transformed aliquots after plating."
          table [["1.5 mL tube", "#{plate_type} Plate"]].concat((transformed_aliquots.collect { |t| t.id }).zip plates.collect{ |p| { content: p.id, check: true } })
        }
      else
        show {
          title "No marker info found"
          note "Place the following tubes into DFP and inform the plasmid owner that they need their Bacterial Marker info entered in the plasmid sample page."
          note "#{transformed_aliquots.collect { |t| t.id }}"
          # note "Discard the following plates:"
          # note "#{plates.collect { |p| p.id }}"
        }
        deleted_plates.concat plates
      end
    end
    actual_plates = all_plates - deleted_plates

    delete all_transformed_aliquots
    if actual_plates.length > 0
      show {
        title "Incubate"
        note "Put all the following plates in 37 C incubator:"
        note actual_plates.collect { |p| "#{p}"}
      }
      move actual_plates, "37 C incubator"
      release actual_plates
    end

    io_hash[:plate_ids].concat actual_plates.collect { |p| p.id }

    # Set tasks in the io_hash to be on plate
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"plated")
      end
    end

    return { io_hash: io_hash }
  end # main

end # Protocol
