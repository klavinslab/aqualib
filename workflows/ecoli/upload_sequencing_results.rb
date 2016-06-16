needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      tracking_num: "10-306533836",
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
    io_hash = { sequencing_verification_task_ids: [], sequencing_task_ids: [], task_ids: [], debug_mode: "No", order_date: "" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    show {
      note "#{io_hash}"
    } if io_hash[:debug_mode].downcase == "yes"

    tracking_num = io_hash[:tracking_num]

    results_info = show {
      title "Check if Sequencing results arrived?"
      check "Go the Genewiz website, log in with lab account (Username: mnparks@uw.edu, password is the lab general password)."
      note "In Recent Results table, click Tracking Number #{tracking_num}, and check if the sequencing results have shown up yet."
      select ["Yes", "No"], var: "results_back_or_not", label: "Do the sequencing results show up?"
    }

    raise "The sequencing results have not shown up yet." if results_info[:results_back_or_not] == "No"

    sequencing_uploads_zip = show {
      title "Upload Genewiz Sequencing Results zip file"
      note "Click the button 'Download All Selected Trace Files' (Not Download All Sequence Files), which should download a zip file named #{tracking_num}-some-random-number.zip."
      note "Upload the #{tracking_num}_ab1.zip file here."
      upload var: "sequencing_results"
    }
    sequencing_uploads = show {
      title "Upload individual sequencing results"
      note "Unzip the downloaded zip file named #{tracking_num}_ab1.zip."
      note "If you are on a Windows machine, right click the #{tracking_num}-some-random-number.zip file, click Extract All, then click Extract."
      note "Upload all the unzipped ab1 file below by navigating to the upzipped folder."
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
        # batched file notif link
        begin
        upload_zip_id = sequencing_uploads_zip[:sequencing_results][0][:id]
        upload_zip = Upload.find(upload_zip_id)
        batched_sequencing_result_url = "<a href=#{upload_zip.url}>#{upload_zip.name}</a>".html_safe
        task.notify "[Data] The batched sequencing results is here #{batched_sequencing_result_url}.", job_id: jid
        # individual file link
        plasmid_stock_id = task.simple_spec[:plasmid_stock_ids][0]
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
