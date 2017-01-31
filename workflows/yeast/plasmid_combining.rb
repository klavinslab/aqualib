needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #stripwell that containing digested plasmids
      task_ids: [23561,23560],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", task_ids: [], plasmids: [], concentrations: [], target_plasmid: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    task_specs = io_hash[:task_ids].map { |tid| find(:task, id: tid)[0].simple_spec }
    input_plasmids = task_specs.map { |ts| ts[:plasmids].map { |pid| find(:sample, id: pid)[0].in("Plasmid Stock")[0] } }
    concentrations = task_specs.map { |ts| ts[:concentrations] }
    target_plasmids = task_specs.map { |ts| find(:sample, id: ts[:target_plasmid])[0].make_item "Plasmid Stock" }

    show do
      title "Tasking debug"

      task_specs.each_with_index do |ts, idx|
        note "Task #{idx}"
        note ts[:plasmids]
        note input_plasmids[idx].class
        note input_plasmids[idx].map { |p| p.id }
        note concentrations[idx]
        note target_plasmids[idx].id
      end
    end

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task, "plasmids combined")
    end

    return { io_hash: io_hash }

  end

end
