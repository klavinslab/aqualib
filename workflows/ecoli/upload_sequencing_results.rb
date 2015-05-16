needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      genewiz_tracking_no: "",
      sequencing_verification_task_ids: [4061,4062,4063,4064,4065,4066,4067,4068,4069,4070,4071,4072,4073,4074,4075,4076,4077,4078,4079,4080,4081,4082,4083,4084,4085,4086,4087,4088,4089,4090],
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
    show {
      title "Upload Genewiz Sequencing Results"
      note "Go the Genewiz website, log in with lab account (Username: mnparks@uw.edu, password is the lab general password)."
      note "Find Genewiz sequencing results for Tracking Number #{genewiz_tracking_no}"
      note "If results are not showed up yet, abort this protocol, it will automatically rescheduled."
      note "Download All Selected Trace Files and then upload the zip file here."
      upload var: "sequencing_#{genewiz_tracking_no}"
    }
    io_hash[:task_ids].concat io_hash[:sequencing_verification_task_ids] if io_hash[:sequencing_verification_task_ids].length > 0

    # Set tasks in the io_hash to be results back
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"results back")
      end
    end

    return { io_hash: io_hash }
  end # main
end # Protocol
