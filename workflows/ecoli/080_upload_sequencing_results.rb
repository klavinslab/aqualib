needs "protocols/mutagenesis_workflow/lib/standard"
needs "protocols/mutagenesis_workflow/lib/cloning"

class Protocol
  
  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      genewiz_tracking_no: "",
      debug_mode: "Yes"
    }
  end
 
  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    if io_hash[:debug_mode] == "Yes"
      def debug
        true
      end
    end
    genewiz_tracking_no = io_hash[:genewiz_tracking_no]
    show {
      title "Upload Genewiz Sequencing Results"
      note "Go the Genewiz website, log in with lab account (Username: mnparks@uw.edu, password is the lab general password)."
      note "Find Genewiz sequencing results for Tracking Number #{genewiz_tracking_no}"
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




