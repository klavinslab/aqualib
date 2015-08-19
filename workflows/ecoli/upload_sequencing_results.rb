needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      genewiz_tracking_no: "",
      sequencing_verification_task_ids: [4090,4089,4088,4087,4062,4061],
      task_ids: [3947,3948,3949,3950,3951,3952,3953,3954,3955,3956,3957,3958,3960,3963,3969,3972,3973,3969,3972,3973],
      sequencing_task_ids: [],
      debug_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    # re define the debug function based on the debug_mode input
    io_hash = { sequencing_verification_task_ids: [], sequencing_task_ids: [], task_ids: [], debug_mode: "No" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    show {
      note "#{io_hash}"
    } if io_hash[:debug_mode].downcase == "yes"

    genewiz_tracking_no = io_hash[:genewiz_tracking_no]
    sequencing_uploads = show {
      title "Upload Genewiz Sequencing Results"
      note "Go the Genewiz website, log in with lab account (Username: mnparks@uw.edu, password is the lab general password)."
      note "Find Genewiz sequencing results for Tracking Number #{genewiz_tracking_no}"
      note "If results are not showed up yet, abort this protocol, it will automatically rescheduled."
      note "Download All Selected Trace Files, unzip the downloaded file and then upload all the upzipped ab1 file here."
      note "You can click Command + A on Mac or Ctrl + A on Windows to select all files."
      note "Wait until all the uploads finished (a number appears at the end of file name). "
      upload var: "sequencing_results"
    }
    # show {
    #   note sequencing_uploads[:sequencing_results].to_json
    # }
    io_hash[:task_ids].concat io_hash[:sequencing_verification_task_ids] if io_hash[:sequencing_verification_task_ids].length > 0

    # Set tasks in the io_hash to be results back
    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"results back")
      if task.task_prototype.name == "Sequencing Verification"
        plasmid_stock_id = task.simple_spec[:plasmid_stock_ids][0]
        begin
          sequencing_uploads[:sequencing_results].each do |result|
            if result[:name].include? plasmid_stock_id.to_s
              upload = Upload.find(result[:id])
              sequencing_result_url = "<a href=#{upload.url}>#{upload.name}</a>".html_safe
              task.notify "[Data] Sequencing data can be accessed here #{sequencing_result_url}", job_id: jid
            end
          end
        rescue
        end
      end
    end

    return { io_hash: io_hash }
  end # main
end # Protocol
