needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol

  include Cloning
  include Standard

  def arguments
    {
      io_hash: {},
      backbone_ids: [],
      inserts_ids: [],
      restriction_enzyme_ids: [],
      debug_mode: "No",
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # setup default values for io_hash.
    io_hash = { backbone_ids: [], inserts_ids: [], restriction_enzyme_ids: [], task_ids: [], debug_mode: "No" }.merge io_hash

    # Set debug based on debug_mode
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    show {
      note io_hash.to_s
    }

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task, "golden gate")
    end

    #io_hash[:golden_gate_result_ids] = golden_gate_results.collect { |g| g.id }

    return { io_hash: io_hash }
  end

end
