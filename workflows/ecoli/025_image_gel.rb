needs "aqualib/lib/standard"
class Protocol

  include Standard

  def arguments
    {
      io_hash: {},
      gel_ids: [28420],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
  	gels = io_hash[:gel_ids].collect { |i| collection_from i }
    if io_hash[:debug_mode] == "Yes"
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