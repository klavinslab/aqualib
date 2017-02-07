needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      task_ids: [23563,23564],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", task_ids: [], plasmids: [], nanograms: [], target_plasmid: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # Find items and things
    tasks = io_hash[:task_ids].map { |tid| find(:task, id: tid)[0] }
    input_plasmids = tasks.map { |t| t.simple_spec[:plasmids].map { |pid| find(:sample, id: pid)[0].in("Plasmid Stock")[0] } }
    nanograms = tasks.map { |t| t.simple_spec[:nanograms] }
    target_plasmids = tasks.map { |t| find(:sample, id: t.simple_spec[:target_plasmid])[0].make_item "Plasmid Stock" }

    take input_plasmids.flatten.uniq, interactive: true, method: "boxes"
    ensure_stock_concentration input_plasmids.flatten.uniq

    # Combine plasmids
    tasks.each_with_index do |t, idx|
      tab = [["Input Plasmid Stock", "Volume (uL)"]]
      input_plasmids[idx].each_with_index do |p, pidx|
        vol = (nanograms[idx][pidx] / p.datum[:concentration]).round(1)
        tab.push [{ content: p.id, check: true }, vol]
      end

      show do
        title "Combine plasmids for #{t.name}"

        note "Label a new tube #{target_plasmids[idx]}. This will be the new plasmid stock."

        note "Pipette the following volumes of input stocks into the output stock."
        table tab
      end

      target_plasmids[idx].datum = target_plasmids[idx].datum.merge({ concentration: 67 })
      target_plasmids[idx].save
    end

    release (input_plasmids + target_plasmids).flatten, interactive: true, method: "boxes"

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task, "plasmids combined")
    end

    return { io_hash: io_hash }

  end

end
