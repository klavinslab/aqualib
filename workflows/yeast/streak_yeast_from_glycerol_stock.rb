# streak yeast plates from glycerol stocks
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_glycerol_stock_ids: [2062,2063],
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

    yeast_glycerol_stocks = []
    yeast_glycerol_stocks = io_hash[:yeast_glycerol_stock_ids].collect { |yid| find(:item, id: yid )[0] }
    streaked_yeast_plates = yeast_glycerol_stocks.collect { |y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}

    num = streaked_yeast_plates.length

    show {
      title "Grab YPAD plates"
      note "Grab #{num} of YPAD plates, label with follow ids"
      note streaked_yeast_plates.collect { |p| "#{p}"}
      note "Take all the plates to the M80 freezer area."
    }

    take yeast_glycerol_stocks, interactive: true, method: "boxes"

    show {
      title "Inoculation"
      note "Inoculate a half-drop amount of frozen glycerol stock in the corner of each plate according to the following table."
      table [["Yeast Glycerol Stock id","Plate id"]].concat(yeast_glycerol_stocks.collect { |y| y.id }.zip streaked_yeast_plates.collect { |y| y.id} )
    }

    release yeast_glycerol_stocks, interactive: true, method: "boxes"

    show {
      title "Streak out the plates"
      note "Wait till the yeast cells are dried on the plate."
      timer initial: { hours: 0, minutes: 3, seconds: 0 }
      note "Streak out the plates using either sterile toothpick or pipette tip by moving forward and back on the agar surface with a shallow angle."
      image "streak_yeast_plate"
    }
    
    move streaked_yeast_plates, "30 C incubator"
    release streaked_yeast_plates, interactive: true

    io_hash[:plate_ids] = streaked_yeast_plates.collect { |x| x.id } 
    return { io_hash: io_hash }

  end # main

end # Protocol