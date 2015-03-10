needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
  
  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      genewiz_tracking_no: "",
      debug_mode: "No"
    }
  end
 
  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    genewiz_tracking_no = io_hash[:genewiz_tracking_no]
    show {
      title "Upload Genewiz Sequencing Results"
      note "Go the Genewiz website, log in with lab account (Username: mnparks@uw.edu, password is the lab general password)."
      note "Find Genewiz sequencing results for Tracking Number #{genewiz_tracking_no}"
      note "If results are not showed up yet, abort this protocol, it will automatically rescheduled."
      note "Download All Selected Trace Files and then upload the zip file here."
      upload var: "sequencing_#{genewiz_tracking_no}"
    }
    task_ids = []
    task_ids.concat io_hash[:task_ids] if io_hash[:task_ids]
    task_ids.concat io_hash[:sequencing_task_ids] if io_hash[:sequencing_task_ids]
    
    # Set tasks in the io_hash to be results back
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"results back")
      end
    end

    return { io_hash: io_hash}
  end # main
end # Protocol




