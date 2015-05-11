needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      gel_ids: [28420],
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
        select ["Yes", "No"], var: "verify#{r[:lane][0]}_#{r[:lane][1]}", label: "Does gel lane on Row #{r[:lane][0]+1} Col #{r[:lane][1]+1} match the expected length of #{r[:length]} bp"
      end
    }

    # show {
    #   routes.each do |r|
    #     note "#{verify_data[:"verify#{r[:lane][0]}_#{r[:lane][1]}".to_sym]}"
    #     note "#{m[r[:lane][0]][r[:lane][1]]}"
    #   end
    # }

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
          end
        end
      end
    end

    show {
      title "Cut gel slices and place them in new 1.5 mL tubes"
      table [
        [ "Row", "Column", "New Gel Slice id", "Length" ]
        ].concat( new_routes.collect { |r| [ r[:lane][0]+1, r[:lane][1]+1, { content: r[:slice_id], check: true }, r[:length] ] } )
        note "Label the tubes with the id shown above."
        note "Wipe the blade with ethanol before each cut."
        warning "Wear blue light goggles during this process!"
      }
      return items
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
      note "The predicted time needed is #{predited_time} min."
    }
    gels = io_hash[:gel_ids].collect { |i| collection_from i }
    take gels, interactive: true
    slices = []
    gels.each do |gel|
      show {
       title "Image gel #{gel.id}"
       check "Clean the transilluminator with ethanol."
       check "Put the gel #{gel.id} on the transilluminator."
       check "Put the camera hood on, turn on the transilluminator and take a picture using the camera control interface on computer."
       note "Rename the picture you just took as gel_#{gel.id}. Upload it!"
       upload var: "my_gel_pic"
     }
    s = gel_band_verify_cut( gel, except: [ [0,0], [1,0] ] )
    produce s
    slices = slices.concat s
   end

  show {
    title "Clean up!"
    note "Turn off the transilluminator"
    note "Dispose of the gel and any gel parts by placing it in the waste container. Spray the surface of the transilluminator with ethanol and wipe until dry using kimwipes or paper towel."
    note "Remove the blue light goggles and put them back where you found them."
    note "Clean up the gel box and casting tray by rinsing with water. Return them to the gel station."
  }

  gels.each do |gel|
    gel.mark_as_deleted
  end

  release slices, interactive: true, method: "boxes"
  
  if io_hash[:task_ids]
    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"gel cut")
    end
  end

  io_hash[:gel_slice_ids] = slices.collect {|s| s.id}
  return { io_hash: io_hash }
end

end



