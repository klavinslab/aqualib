needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_overnight_ids: [],
      media_type: "800 mL SC liquid (sterile)",
      volume: 2,
      inducer: "beta-estradiol",
      debug_mode: "Yes"
    }
  end

  def main
  	io_hash = input[:io_hash]
  	io_hash = input if input[:io_hash].empty?
  	if io_hash[:debug_mode] == "Yes"
        def debug
          true
        end
    end
    media_type = io_hash[:media_type]
    volume = io_hash[:volume]
    inducer = io_hash[:inducer]

    yeast_overnights = io_hash[:yeast_overnight_ids].collect { |y| find(:item, id: y)[0] }
    yeast_samples = yeast_overnights.collect { |y| y.sample }
    #tube_arrays = produce spread yeast_samples, "TubeArray", 1, 12
    diluted_yeast_overnights = yeast_overnights.collect{ |y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"}
  	show {
  		title "Media preparation in media bay"
  		check "Grab #{yeast_overnights.length} of 14 mL Test Tube"
  		check "Add #{volume} mL of #{media_type} to each empty 14 mL test tube using serological pipette"
  		check "Write down the following ids on cap of each test tube using dot labels #{diluted_yeast_overnights.collect {|x| x.id}}"
  		check "Pipette 2 µL of 100 µM #{inducer} into each tube, making 100 nM final concentration." if inducer.length > 0
  	}
  	take yeast_overnights, interactive: true
  	show {
  		title "Make 1:100 Dilution"
  		note "Pipette 20 µL of yeast overnights into newly labeled 14 mL tubes according to the following table."
  		table [["Yeast Overnight id", "Newly labeled 14 mL tube"]].concat(yeast_overnights.collect {|y| y.id}.zip diluted_yeast_overnights.collect {|y| y.id})
  	}
  	diluted_yeast_overnights.each do |y|
  		y.location = "30 C shaker incubator"
      y.save
    end
  	release yeast_overnights, interactive: true
  	release diluted_yeast_overnights, interactive: true
      
    io_hash[:diluted_yeast_overnight_ids] = diluted_yeast_overnights.collect {|x| x.id}
    return { io_hash: io_hash }
  end # main
end # main
