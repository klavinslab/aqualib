needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      template_ids: [70478, 70675],
      enzymes: [[51],[51,256]],
      band_lengths: [[54321, 12543], [12345]],
      stripwell_ids: [70770],
      debug_mode: "no"
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "Yes", stripwell_ids: [], enzymes: [[]], band_lengths: [[]], task_ids: [], group: "technicians" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    stripwells = io_hash[:stripwell_ids].map { |swid| find(:item, id: swid)[0] }

    take stripwells, interactive: true

    stripwells.each { |sw| sw.location = "R4 (beneath the DI dispensers)" }

    release stripwells, interactive: true

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task, "moved to fridge")
      end
    end

    return { io_hash: io_hash }
  end
end