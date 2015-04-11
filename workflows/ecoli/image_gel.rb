needs "aqualib/lib/standard"
class Protocol

  include Standard

  def arguments
    {
      io_hash: {},
      gel_ids: [28420],
      debug_mode: "No"
    }
  end

  def gel_band_verify col, options = {}
    m = col.matrix
    routes = []
    opts = { except: [] }.merge options

    (0..m.length-1).each do |i|
      (0..m[i].length-1).each do |j|
        if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
          s = find(:sample,{ id: m[i][j] })[0]
          length = s.properties
          routes.push lane: [i,j], length: length
        end
      end
    end

    verify_data = show {
      title "Verify that each lane matches expected size"
      routes.each_with_index do |r,idx|
        select ["Yes", "No"], var: "verify#{r[:lane][0]}_#{r[:lane][1]}", label: "Does gel lane on Row #{r[:lane][0]+1} Col #{r[:lane][1]+1} match the expected length of #{r[:length]} bp"
      end
    }

  end #gel_band_verify_cut

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
  	gels = io_hash[:gel_ids].collect { |i| collection_from i }
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    take gels, interactive: true
  	gels.each do |gel|
  		show {
  			title "Image gel #{gel.id}"
  			check "Clean the transilluminator with ethanol."
  			check "Put the gel #{gel.id} on the transilluminator."
  			check "Put the camera hood on, turn on the transilluminator and take a picture using the camera control interface on computer."
  			note "Rename the picture you just took as gel_#{gel.id}. Upload it!"
  			upload var: "my_gel_pic"
  		}
  	end

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"gel imaged")
      end
    end

  	release gels, interactive: true
    return { io_hash: io_hash }
  end # main

end