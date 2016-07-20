needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"
require 'matrix'

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      gel_ids: [22668,20059],
      task_ids: [5826,3865],
      debug_mode: "No"
    }
  end

  def gel_band_verify_cut col, options = {}
    m = col.matrix
    routes = []
    opts = { except: [] }.merge options

    (0..m.length-1).each do |i|
    	(0..m[i].length-1).each do |j|
        if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
          s = find(:sample,{id: m[i][j]})[0]
          length = s.properties["Length"]
          routes.push lane: [i,j], length: length
        end
      end
    end

    verify_data = show {
      title "Verify that each lane matches expected size"
  		# table [[ "Row", "Column", "Expected fragment size" ]].concat( routes.collect { |r| [ r[:lane][0]+1, r[:lane][1]+1, { content: r[:length], check: true }] } )
      routes.each_with_index do |r,idx|
        select ["Yes", "No"], var: "verify#{r[:lane][0]}_#{r[:lane][1]}", label: "Does gel lane on Row #{r[:lane][0]+1} Col #{r[:lane][1]+1} match the expected length of #{r[:length]} bp?"
        get "text", var: "comment#{r[:lane][0]}_#{r[:lane][1]}", label: "Leave comments below (band width, proximity to other bands, etc.)."
        warning "New row!".upcase if routes[idx+1] && routes[idx+1][:lane][0] != r[:lane][0]
      end
      check "Have a lab manager or grad student verify your choices before moving on to the next step."
      get "text", var: "initials", label: "Lab manager or grad student initials"
    }

    routes.each do |r|
      m[r[:lane][0]][r[:lane][1]] = 3.14 if verify_data[:"verify#{r[:lane][0]}_#{r[:lane][1]}".to_sym] == "No"
    end

    items = []
    new_routes = []
    (0..m.length-1).each do |i|
      (0..m[i].length-1).each do |j|
        if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
          if m[i][j] == 3.14
            new_routes.push lane: [i,j], slice_id: "Do not cut", length: "NA"
          else
            s = find(:sample,{id: m[i][j]})[0]
            length = s.properties["Length"]
            item = s.make_item "Gel Slice"
            items.push item
            new_routes.push lane: [i,j], slice_id: item.id, length: length
            note = verify_data[:"comment#{i}_#{j}".to_sym]
            item.notes = note
          end
        end
      end
    end

    show {
      title "Label the 1.5 mL tubes"
      note "Label the tubes with the following ids:"
      note new_routes.map { |r| "#{r[:slice_id]}" }.join(", ")
    }

    show {
      title "Cut gel slices and place them in new 1.5 mL tubes"
      warning "Wear blue light goggles during this process!"
      table [
        [ "Row", "Column", "New Gel Slice id", "Length" ]
        ].concat( new_routes.collect { |r| [ r[:lane][0]+1, r[:lane][1]+1, { content: r[:slice_id], check: true }, r[:length] ] } )
      image "cut_gel_video"
    }
    return items, verify_data
  end #gel_band_verify_cut

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "No", gel_ids: [], size: 0 }.merge io_hash
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    predited_time = time_prediction io_hash[:size], "cut_gel"
    show {
      title "Protocol Information"
      note "This protocol will take gel pictures and cut gel into gel slices."
      warning "Clean blue light goggles and put them on before beginning this protocol."
      note "The predicted time needed is #{predited_time} min."
    }
    gels = io_hash[:gel_ids].collect { |i| collection_from i }
    take gels, interactive: true
    slices = []
    gel_uploads = {}
    gels.each do |gel|
      gel_uploads[gel.id] = show {
        title "Image gel #{gel.id}"
        check "Clean the transilluminator with ethanol."
        check "Put the gel #{gel.id} on the transilluminator."
        check "Turn off the room lights before turning on the transilluminator."
        check "Put the camera hood on, turn on the transilluminator and take a picture using the camera control interface on computer."
        check "Check to see if the picture matches the gel before uploading."
        check "Rename the picture you just took as gel_#{gel.id}. Upload it!"
        upload var: "my_gel_pic"
      }
      s, verify_data = gel_band_verify_cut( gel, except: [ [0,0], [1,0] ] )
      produce s
      slices = slices.concat s
    end

    weights = show {
      title "Weigh each gel slice."
      check "Zero the scale with an empty 1.5 mL tube."
      check "Weigh each slice and enter the recorded weights in the following:"
      gel_slices.each do |gs|
        get "number", var: "w#{gs.id}", label: "Enter a number for tube #{gs.id}", default: 0.123
      end
    }
    gel_slices.each { |gs| gs.associate "weight", weights[:"w#{gs.id}".to_sym] }

    show {
      title "Clean up!"
      check "Turn off the transilluminator"
      check "Dispose of the gel and any gel parts by placing it in the waste container. Spray the surface of the transilluminator with ethanol and wipe until dry using kimwipes or paper towel."
      check "Remove the blue light goggles, clean them, and put them back where you found them."
      check "Clean up the gel box and casting tray by rinsing with water. Return them to the gel station."
      check "Dispose gloves after leaving the room."
    }

    gels.each do |gel|
      gel.mark_as_deleted
    end

    release slices, interactive: true, method: "boxes"

    errors = []
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"gel cut")
        if task.task_prototype.name == "Fragment Construction"
          fragment_ids = task.simple_spec[:fragments]
          associated_gel_ids = {}
          gels.each do |gel|
            gel_fragment_ids = gel.matrix
            gel_fragment_ids.flatten!
            gel_fragment_ids.delete(-1)
            if (fragment_ids & gel_fragment_ids).any?
              associated_gel_ids[gel.id] =  fragment_ids & gel_fragment_ids
            end
          end
          notifs = []
          associated_gel_ids.each do |id, fragment_ids|
            begin
              upload_id = gel_uploads[id][:my_gel_pic][0][:id]
              upload_url = Upload.find(upload_id).url
              associated_gel = collection_from id
              gel_matrix = associated_gel.matrix
              fragment_ids_link = fragment_ids.collect { |fid| item_or_sample_html_link(fid, :sample) + " (location: #{Matrix[*gel_matrix].index(fid).collect { |i| i + 1}.join(',')}; length: #{find(:sample, id: fid)[0].properties["Length"]})" }.join(", ")
              image_url = "<a href=#{upload_url} target='_blank'>image</a>".html_safe
              notifs.push "#{'Fragment'.pluralize(fragment_ids.length)} #{fragment_ids_link} associated gel: #{item_or_sample_html_link id, :item} (#{image_url}) is uploaded."
              #gel_matrix.each_with_index { |r, r_idx|
              #  r.each_with_index { |c, c_idx|
              #    comment = verify_data["comment#{r_idx}_#{c_idx}".to_sym]
              #    if comment != ""
              #      comment_notifs.push "The following comment was left on gel #{c}: #{comment}"
              #    end
              #  }
              #}
            rescue Exception => e
              errors.push e.to_s
            end
          end
          notifs.each { |notif| task.notify "[Data] #{notif}", job_id: jid }
        end
      end
    end

    io_hash[:errors] = errors
    io_hash[:gel_slice_ids] = slices.collect {|s| s.id}
    return { io_hash: io_hash }
  end
end