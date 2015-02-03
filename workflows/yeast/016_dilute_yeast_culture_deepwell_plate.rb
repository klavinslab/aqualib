needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      deepwell_plate_ids: [32311],
      media_type: "800 mL SC liquid (sterile)",
      volume: 1000,
      dilution_rate: 0.01,
      inducers: ["20 µM auxin"],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash = { deepwell_plate_ids: [] }.merge io_hash
    deepwell_plates = io_hash[:deepwell_plate_ids].collect { |i| collection_from i }
    yeast_deepwell_plates = deepwell_plates.collect { produce new_collection "Eppendorf 96 Deepwell Plate", 8, 12 }
    take deepwell_plates, interactive: true
    show {
      note "#{io_hash}"
    }
    show {
      title "Take new deepwell plates"
      note "Grab #{yeast_deepwell_plates.length} Eppendorf 96 Deepwell Plate. Label with #{yeast_deepwell_plates.collect {|d| d.id}}."
      yeast_deepwell_plates.each_with_index do |y,idx|
        note "Add #{io_hash[:volume]*(1-io_hash[:dilution_rate])} µL of #{io_hash[:media_type]} into wells #{deepwell_plates[idx].non_empty_string}."
      end
    }
    show {
      title "Vortex the deepwell plates."
      note "Vortex the deepwell plates #{deepwell_plates.collect { |d| d.id }} on a table top vortexer at settings 7 for about 20 seconds."
    }
    transfer( deepwell_plates, yeast_deepwell_plates ) {
      title "Transfer #{io_hash[:volume]*io_hash[:dilution_rate]} µL"
      note "Using either 6 channel pipettor or single pipettor."
    }
    show {
      title "Place the deepwell plates in the washing station"
      note "Place the following deepwell plates #{deepwell_plates.collect { |d| d.id }} in the washing station "
    }
    deepwell_plates.each do |d|
      d.mark_as_deleted
      d.save
    end
    yeast_deepwell_plates.each do |d|
      d.location = "30 C shaker incubator"
      d.save
    end
    release yeast_deepwell_plates, interactive: true
    io_hash[:yeast_deepwell_plate_ids] = yeast_deepwell_plates.collect { |d| d.id }
    return { io_hash: io_hash }
  end # main
end # main
