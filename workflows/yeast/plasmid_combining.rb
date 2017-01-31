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

    tasks = io_hash[:task_ids].map { |tid| find(:task, id: tid)[0].simple_spec }
    input_plasmids = tasks.map { |t| t.simple_spec[:plasmids].map { |pid| find(:sample, id: pid)[0].in("Plasmid Stock")[0] } }
    concentrations = tasks.map { |t| t.simple_spec[:concentrations] }
    target_plasmids = tasks.map { |t| find(:sample, id: t.simple_spec[:target_plasmid])[0].make_item "Plasmid Stock" }

    show do
      title "Tasking debug"

      tasks.each_with_index do |t, idx|
        note "Task #{idx}"
        note t.simple_spec[:plasmids]
        note input_plasmids[idx].class
        note input_plasmids[idx].map { |p| p.id }
        note concentrations[idx]
        note target_plasmids[idx].id
      end
    end

    tasks.each_with_index do |t, idx|
      tab = [["Input Plasmid Stock", "Volume (uL)"]]
      input_plasmids[idx].each_with_index do |p, pidx|
        vol = 1000 / concentrations[idx][pidx]
        tab.push [{ content: p.id, check: true }, vol]
      end

      show do
        title "Combine plasmids for #{task.name}"

        check "Label a new tube #{target_plasmids[idx]} for the new stock"

        note "Pipette the following volumes of input stocks into the output stock"
        table tab
      end

      target_plasmids[idx].datum = target_plasmids[idx].datum.merge({ concentration: 67 })
    end

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task, "plasmids combined")
    end

    return { io_hash: io_hash }

  end

end
