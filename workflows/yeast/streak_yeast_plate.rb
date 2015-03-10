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
      yeast_overnight_ids: [17374,17373],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", yeast_overnight_ids: [], yeast_glycerol_stock_ids: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    yeast_glycerol_stocks = io_hash[:yeast_glycerol_stock_ids].collect { |yid| find(:item, id: yid )[0] }
    yeast_overnights = io_hash[:yeast_overnight_ids].collect { |yid| find(:item, id: yid)[0] }

    glycerol_streaked_yeast_plates = yeast_glycerol_stocks.collect { |y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}

    overnight_streaked_yeast_plates = yeast_overnights.collect { |y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}

    streaked_yeast_plates = glycerol_streaked_yeast_plates + overnight_streaked_yeast_plates

    num = streaked_yeast_plates.length

    show {
      title "Grab YPAD plates"
      check "Grab #{num} of YPAD plates, label with follow ids:"
      note streaked_yeast_plates.collect { |p| "#{p}"}
    }

    if yeast_glycerol_stocks.length > 0

      take yeast_glycerol_stocks
      inoculation_tab = [["Gylcerol Stock id", "Location", "Yeast plate id"]]
      yeast_glycerol_stocks.each_with_index do |y, idx|
        inoculation_tab.push [ { content: y.id, check: true }, y.location, glycerol_streaked_yeast_plates[idx].id ]
      end

      show {
        title "Inoculation from glycerol stock"
        check "Go to M80 area to perform following inoculation steps."
        check "Grab one glycerol stock at a time out of the M80 freezer."
        check "Use a sterile 100 µL tip with pipettor and vigerously scrape a big chuck of glycerol stock swirl onto a corner of the yeast plate agar side following the table below."
        table inoculation_tab
      }
      release yeast_glycerol_stocks

    end

    if yeast_overnights.length > 0

      take yeast_overnights, interactive: true

      inoculation_tab = [["Yeast overnight id", "Yeast plate id"]]
      yeast_overnights.each_with_index do |y, idx|
        inoculation_tab.push [ { content: y.id, check: true }, overnight_streaked_yeast_plates[idx].id ]
      end

      show {
        title "Inoculation from overnight"
        check "Pipette 20 µL from each overnight onto a corner of the yeast plate agar side."
        table inoculation_tab
      }

      release yeast_overnights

    end

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