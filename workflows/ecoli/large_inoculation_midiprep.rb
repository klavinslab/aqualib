needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      small_overnight_ids: [55418,63226,63225],
      debug_mode: "no",
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    # making sure have the following hash indexes.
    io_hash = { small_overnight_ids: [] }.merge io_hash

    small_overnights = io_hash[:small_overnight_ids].map { |oid| find(:item, id: pid)[0] }
    large_overnights = small_overnights { |o| produce new_sample o.sample.name, of: "Plasmid", as: "TB Overnight of Plasmid (100 mL)" }

    show {
      title "Media preparation in media bay"

      check "Label new tubes, and add 100 mL of media and marker(s) to them according to the following table."

      table [["Large Overnight ID", "Marker"]]
            .concat(large_overnights.map { |o| o.id }
            .zip small_overnights.map { |o| { content: o.datum[:marker], check: true } })
    }

    take small_overnights, interactive: true

    show {
      title "Inoculation from small overnight"

      note "Inoculate 200 µL from each of the following small overnights into the large tubes according to the following table."

      table [["Small Overnight ID", "Large Overnight ID"]]
            .concat(small_overnights.map { |o| o.id }
            .zip large_overnights.map { |o| { content: o.id, check: true } })
    }

    delete small_overnights

    large_overnights.each do |o|
      o.location = "37 C shaker incubator"
      o.save
    end

    release large_overnights, interactive: true

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"large overnight")
      end
    end

    io_hash[:overnight_ids] = large_overnights.collect { |o| o.id }
    return { io_hash: io_hash }

  end # main
end # Protocol
