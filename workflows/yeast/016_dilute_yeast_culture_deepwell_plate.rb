needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      deepwell_ids: [],
      yeast_overnight_ids: [],
      media_type: "800 mL SC liquid (sterile)",
      volume: 1,
      inducer: "beta-estradiol",
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode] || "No"
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    media_type = io_hash[:media_type]
    volume = io_hash[:volume]
    inducer = io_hash[:inducer] || ""
    yeast_overnights = io_hash[:yeast_overnight_ids].collect { |y| find(:item, id: y)[0] }
    yeast_samples = yeast_overnights.collect { |y| y.sample }
    deepwells = produce spread yeast_samples, "Eppendorf 96 Deepwell Plate", 8, 12
    load_samples( ["Yeast overnights"], [
        yeast_overnights,
      ], deepwells )
    show {
      title "Add inducer"
      note "Add 1 µL of 100 µM #{inducer} into each tube"
    } if inducer.length > 0
    deepwells.each do |x|
      x.location = "30 C shaker incubator"
      x.save
    end
    release yeast_overnights, interactive: true
    release deepwells, interactive: true
    io_hash[:deepwell_ids] = deepwells.collect {|d| d.id}
    return { io_hash: io_hash }
  end # main
end # main
