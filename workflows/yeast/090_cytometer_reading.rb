needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the item id that you are going to start overnight with
      yeast_deepwell_plate_ids: [32147],
      yeast_ubottom_plate_ids: [32179],
      volume: 100,
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
    io_hash = { yeast_deepwell_plate_ids: [], yeast_ubottom_plate_ids: [] }.merge io_hash
    yeast_deepwell_plates = io_hash[:yeast_deepwell_plate_ids].collect { |i| collection_from i }
    yeast_ubottom_plates = io_hash[:yeast_ubottom_plate_ids].collect { |i| collection_from i }
    show {
      title "Protocol information"
      note "This protocol is used to take cytometer readings from deepwell plates using u-bottom plates."
    }
    if io_hash[:yeast_ubottom_plate_ids] == []
      yeast_ubottom_plates = yeast_deepwell_plates.collect { produce new_collection "96 U-bottom Well Plate", 8, 12 }
      show {
        title "Grab #{yeast_ubottom_plates.length} 96 U-bottom Well Plate"
        note "Grab #{yeast_ubottom_plates.length} 96 U-bottom Well Plate and label with #{yeast_ubottom_plates.collect { |y| y.id }}."
      }
    end
    take yeast_deepwell_plates + yeast_ubottom_plates, interactive: true
    transfer( yeast_deepwell_plates, yeast_ubottom_plates ) {
      title "Transfer #{io_hash[:volume]} µL"
      note "Using either 6 channel pipettor or single pipettor."
    }
    release yeast_deepwell_plates, interactive: true
    show {
      title "Cytometer reading"
      check "Go to the software, click Eject Plate if the CSampler holder is not outside."
      check "Place the loaded u-bottom plate on the CSampler holder"
      check "Click new workspace, choose the following settings."
      check "Click autorun."
    }
    show {
      title "Clean run"
      check "Click open workspace, go to MyDocuments folder to find clean_regular_try.c6t file and open it."
      check "Put the cleaning 24 well plate on the plate holder, make sure there is still liquid left in tubes at D4, D5, D6. Replace with a full reagnent tube if tube has lower than 50 µL of liquid in it."
      check "Click autorun."
    }
    release yeast_ubottom_plates, interactive: true
    io_hash[:yeast_ubottom_plates_ids] = yeast_ubottom_plates.collect {|d| d.id}
    return { io_hash: io_hash }
  end # main

end # Protocol

