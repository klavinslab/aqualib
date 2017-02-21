needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      plasmid_stock_ids: [9189,11546,11547,12148,12149,15150,15152,15318,15417,16151,16149],
      debug_mode: "Yes"
    }
  end
  def update_batch_matrix batch, num_samples, plate_type
    rows = batch.matrix.length
    columns = batch.matrix[0].length
    batch.matrix = fill_array rows, columns, num_samples, find(:sample, name: "#{plate_type}")[0].id
    batch.save
  end # update_batch_matrix

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { plasmid_stock_ids: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # list of antibiotic plate for yeast selection
    # ClonNat, NatMX, 25 µL, G418, KanMX, 300 µL, Hygromycin, HygMX, 200 µL, Zeocin, Bleo, 50 µL.

    plasmid_marker_hash = Hash.new {|h,k| h[k] = 0 }

    #specifically for the W17 Lab class--antibiotic plates need to be SDO -Ura -Leu instead of YPAD
    ura_leu_plate_markers = Hash.new { |h, k| h[k] = 0 }
    batch = nil

    markers = [ :nat, :kan, :hyg, :ble ]
    antibiotic_hash = { nat: "ClonNat", kan: "G418", hyg: "Hygro", ble: "Bleo" }
    volume_hash = { nat: 25, kan: 300, hyg: 200, ble: 50 }

    io_hash[:plasmid_stock_ids].each do |pid|
      marker = find(:item, id: pid)[0].sample.properties["Yeast Marker"].downcase[0,3].to_sym
      project = find(:item, id: pid)[0].sample.project
      if markers.include? marker && io_hash[:task_hash]        
        task_id = io_hash[:task_hash].select { |h| h[:plasmid_stock_ids] == pid }[0][:task_id]
        set_task_status(find(:task, id: task_id)[0],"plate made")
      end

      if project.include? "LabW17" #filtering inputs based on projects
        ura_leu_plate_markers.store(marker, ura_leu_plate_markers[marker] + 1)
        batch =  Collection.where(object_type_id: 493).select { |b| b.data.include? "11783" }.first
      else
        plasmid_marker_hash.store(marker, plasmid_marker_hash[marker] + 1)
      end
    end


    if ura_leu_plate_markers && batch
      ura_leu_plate_markers.each do |marker, num|
        num_plates = batch.num_samples
        update_batch_matrix batch, num_plates - num, "SDO -Leu -Ura"
        plate_batch_id = "#{batch.id}"
        batch.mark_as_deleted if (num_plates - num) == 0

        show do
          title "Grab SDO -Leu -Ura plates and #{antibiotic_hash[marker]} stock"
          check "Grab #{num} SDO -Leu -Ura plates from batch #{plate_batch_id}."
          check "Grab #{(num * volume_hash[marker] / 1000.0).ceil} 1 mL #{antibiotic_hash[marker]} stock in SF1 or M20."
          check "Wait for the #{antibiotic_hash[marker]} stock to thaw."
          check "Use sterile beads to spread #{volume_hash[marker]} µL of #{antibiotic_hash[marker]} to each SDO -Leu -Ura plates, mark each plate with #{antibiotic_hash[marker]} in RED sharpie."
          check "Wrap plates in foil and place them agar side down in the dark fume hood to dry."
        end

        produce new_sample "SDO -Leu -Ura + #{antibiotic_hash[marker]}" , of: "SDO -Leu -Ura + #{antibiotic_hash[marker]}", as: "Agar Plate"
      end 
    end

    plasmid_marker_hash.each do |marker, num|

      if markers.include? marker
        overall_batches = find(:item, object_type: { name: "Agar Plate Batch" }).map{ |b| collection_from b }
        plate_batch = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0].name == "YPAD" }
        plate_batch_id = "none" 
        if plate_batch.present?
          plate_batch_id = "#{plate_batch.id}"
          num_plates = plate_batch.num_samples
          update_batch_matrix plate_batch, num_plates - num, "YPAD"

          if num_plates - num == 0
            plate_batch.mark_as_deleted
          end

          if num_plates < num 
            num_left = num - num_plates
            plate_batch_two = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0].name == "YPAD"}
            update_batch_matrix plate_batch_two, plate_batch_two.num_samples - num_left, "YPAD" if plate_batch_two.present?
            plate_batch_id = plate_batch_id + ", #{plate_batch_two.id}" if plate_batch_two.present?
          end
        end
        show {
          title "Grab YPAD plates and #{antibiotic_hash[marker]} stock"
          check "Grab #{num} YPAD plates from batch #{plate_batch_id}."
          check "Grab #{(num * volume_hash[marker] / 1000.0).ceil} 1 mL #{antibiotic_hash[marker]} stock in SF1 or M20."
          check "Wait for the #{antibiotic_hash[marker]} stock to thaw."
          check "Use sterile beads to spread #{volume_hash[marker]} µL of #{antibiotic_hash[marker]} to each YPAD plates, mark each plate with #{antibiotic_hash[marker]} in RED sharpie."
          check "Wrap plates in foil and place them agar side down in the dark fume hood to dry."
        }

        produce new_sample "YPAD + #{antibiotic_hash[marker]}" , of: "YPAD + #{antibiotic_hash[marker]}", as: "Agar Plate"
      end
    end

    if plasmid_marker_hash
      show {
        title "Let plate dry"
        check "Place the plates with agar side down in the dark fume hood to dry."
        note "Noting that placing agar side down is opposite of what you normally do when placing plates in incubator. This will help the antibiotic spread into the agar."
      }
    else
      show {
        title "No antibiotic plate needs to be made."
        note "No antibiotic plate needs to be made. Thanks for your effort."
      }
    end

    return { io_hash: io_hash }

  end # main

end # Protocol
