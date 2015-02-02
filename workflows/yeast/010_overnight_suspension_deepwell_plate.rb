needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the item id that you are going to start overnight with
      yeast_item_ids: [13011,15872],
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL SC liquid (sterile)",
      inducers: ["10 µM auxin"],
      dilution_rate: 0.01,
      #The volume of the overnight suspension to make
      volume: "1000",
      debug_mode: "No"
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
    io_hash = { inducers: [] }.merge io_hash
    yeast_items = io_hash[:yeast_item_ids].collect { |yid| find(:item, id: yid )[0] }
    inducer_additions = io_hash[:yeast_item_ids].collect { "None" }
    io_hash[:inducers].each do |inducer|
      yeast_items.concat io_hash[:yeast_item_ids].collect { |yid| find(:item, id: yid )[0] }
      inducer_additions.concat io_hash[:yeast_item_ids].collect { "#{inducer}" }
    end
    yeast_strains = yeast_items.collect { |y| y.sample }
    take yeast_items.uniq, interactive: true
    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from glycerol stocks, plates or overnight suspensions into Eppendorf 96 Deepwell Plate."
    }
    deepwells = produce spread yeast_strains, "Eppendorf 96 Deepwell Plate", 8, 12
    show {
      title "Take deepwell plate"
      note "Grab #{deepwells.length} Eppendorf 96 Deepwell Plate. Label with #{deepwells.collect {|d| d.id}}."
    }
    yeast_items_str = yeast_items.collect { |y| y.id.to_s }
    media_str = (1..yeast_items.length).collect { |y| "#{io_hash[:volume]} µL"}
    load_samples_variable_vol( ["#{io_hash[:media_type]}","Yeast items", "Inducers"], [
        media_str, yeast_items_str,inducer_additions
      ], deepwells ) 
    show {
      title "Seal the plate with a breathable sealing film"
      note "Put a breathable sealing film on the plate after inoculation."
    }
    deepwells.each do |d|
      d.location = "30 C shaker incubator"
      d.save
    end
    release deepwells + yeast_items.uniq, interactive: true
    io_hash[:deepwell_plate_ids] = deepwells.collect {|d| d.id}
    return { io_hash: io_hash }
  end # main

end # Protocol
