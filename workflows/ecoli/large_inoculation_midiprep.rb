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
    io_hash = { plate_ids: [], num_colonies: [] }.merge io_hash

    Inoculate 200 uL of the small inoculation into 100  mL LB + marker.
    Incubate for 12 hrs.

    overnight_marker_hash.each do |marker, overnight|
      show {
        title "Media preparation in media bay"
        check "Grab #{overnight.length} of 14 mL Test Tube"
        check "Add 3 mL of #{marker} to each empty 14 mL test tube using serological pipette"
        check "Write down the following ids on cap of each test tube using dot labels #{overnight.collect {|x| x.id}}"
      }
    end

    take plates, interactive: true

    show {
      title "Inoculation from plate"
      note "Use 10 µL sterile tips to inoculate colonies from plate into 14 mL tubes according to the following table."
      check "Mark each colony on the plate with corresponding overnight id. If the same plate id appears more than once in the table, inoculate different isolated colonies on that plate."
      table [["Plate id", "Overnight id"]].concat(colony_plates.collect { |p| p.id }.zip overnights.collect { |o| { content: o.id, check: true } })
    }

    overnights.each do |o|
      o.location = "37 C shaker incubator"
      o.save
    end

    release overnights, interactive: true
    release plates, interactive: true

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"large overnight")
      end
    end

    io_hash[:overnight_ids] = overnights.collect { |o| o.id }
    return { io_hash: io_hash }

  end # main
end # Protocol
