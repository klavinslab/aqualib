needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning



  def arguments
    {
      io_hash: {},
      transformed_aliquots_ids: [9191,9190,8418],
      debug_mode: "No",
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

    plates_marker_hash = Hash.new { |h,k| h[k] = [] }
    all_plates.each do |p|
      plates_marker_hash[p.sample.properties["Bacterial Marker"].downcase[0,3]].push p
    end

    deleted_plates = []

    plates_marker_hash.each do |marker, plates|
      transformed_aliquots = plates.collect { |p| all_transformed_aliquots[all_plates.index(p)] }
      unless marker == ""
        marker = "chlor" if marker == "chl"
        plates_with_initials = plates.collect {|x| "#{x.id} "+ name_initials(x.sample.user.name)}
        num = plates.length
        show {
          title "Grab #{num} #{"plate".pluralize(num)}"
          check "Grab #{num} LB+#{marker[0].upcase}#{marker[1..marker.length]} Plate (sterile)"
          check "Label with the following ids #{plates_with_initials}"
        }
        show {
          title "Plating"
          check "Use sterile beads to plate 200 µL from transformed aliquots (1.5 mL tubes) on to the plates following the table below."
          check "Discard used transformed aliquots after plating."
          table [["1.5 mL tube", "LB+#{marker[0].upcase}#{marker[1,2]} Plate"]].concat((transformed_aliquots.collect { |t| t.id }).zip plates.collect{ |p| { content: p.id, check: true } })
        }
      else
        show {
          title "No marker info found"
          note "Place the following tubes into DFP and inform the plasmid owner that they need their Bacterial Marker info entered in the plasmid sample page."
          note "#{transformed_aliquots.collect { |t| t.id }}"
          note "Discard the following plates:"
          note "#{plates.collect { |p| p.id }}"
        }
        deleted_plates.concat plates
      end
    end

    actual_plates = all_plates - deleted_plates

    delete all_transformed_aliquots
    delete deleted_plates

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
