# streak yeast plates from glycerol stocks
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_glycerol_stock_ids: [2062,2063,8160,8161,8162,8163],
      yeast_overnight_ids: [11208,11209],
      yeast_selective_plate_types: [],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", yeast_overnight_ids: [], yeast_glycerol_stock_ids: [], yeast_selective_plate_types: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    num_of_section = 4

    yeast_glycerol_stocks = io_hash[:yeast_glycerol_stock_ids].collect { |yid| find(:item, id: yid )[0] }

    if yeast_glycerol_stocks.length > 0

      yeast_strains = yeast_glycerol_stocks.collect { |y| y.sample }

      # glycerol_streaked_yeast_plates = yeast_glycerol_stocks.collect { |y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}

      glycerol_streaked_yeast_plates = produce spread yeast_strains, "Divided Yeast Plate", 1, num_of_section

      show {
        title "Grab yeast plates"
        if glycerol_streaked_yeast_plates.length > 0
          check "Grab #{glycerol_streaked_yeast_plates.length} of YPAD plates, label with follow ids:"
          note glycerol_streaked_yeast_plates.collect { |p| "#{p}"}
          check "Divide up each plate with #{num_of_section} sections and mark each with circled #{(1..num_of_section).to_a.join(',')}"
          image "divided_yeast_plate"
        end
      }

      take yeast_glycerol_stocks
      # inoculation_tab = [["Gylcerol Stock id", "Location", "Yeast plate id"]]
      # yeast_glycerol_stocks.each_with_index do |y, idx|
      #   inoculation_tab.push [ { content: y.id, check: true }, y.location, glycerol_streaked_yeast_plates[idx].id ]
      # end

      show {
        title "Inoculation from glycerol stock in M80 area"
        check "Grab the plates and go to M80 area to perform inoculation steps in the next pages."
        note "Be extremely cautious about your sterile technique during inoculation."
        note "Grab one glycerol stock at a time out of the M80 freezer."
      }

      yeast_glycerol_stock_locations = yeast_glycerol_stocks.collect { |y| y.location }

      load_samples_variable_vol( [ "Glycerol Stock id", "Freezer box slot"], [
          yeast_glycerol_stocks.collect { |y| "#{y}" }, yeast_glycerol_stock_locations
        ], glycerol_streaked_yeast_plates ) {
          warning "Be extremely cautious about your sterile technique."
          image "divided_yeast_plate_colony"
          check "Grab one glycerol stock at a time out of the M80 freezer."
          check "Use a sterile 100 µL tip with pipettor and vigorously scrape a big chuck of glycerol stock swirl onto a side corner of the yeast plate agar section"
        }

      release yeast_glycerol_stocks

    end

    overnight_streaked_yeast_plates = []

    if io_hash[:yeast_overnight_ids].length > 0

      yeast_overnights = io_hash[:yeast_overnight_ids].collect { |yid| find(:item, id: yid)[0] }
      overnight_streaked_yeast_plates = yeast_overnights.collect { |y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}

      show {
        title "Grab yeast plates"
        if io_hash[:yeast_selective_plate_types].length > 0
          io_hash[:yeast_selective_plate_types].each_with_index do |plate_type, idx|
            check "Grab one #{plate_type} plate and label with #{overnight_streaked_yeast_plates[idx].id}"
          end
        else
          check "Grab #{overnight_streaked_yeast_plates.length} of YPAD plates, label with follow ids:"
          note overnight_streaked_yeast_plates.collect { |p| "#{p}"}
        end
      }

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

      show {
        title "Clean up"
        note "Discard yeast overnights with the following ids. If it is a plastic tube, push down the cap to seal the tube and discard into biohazard box. If it is a glass tube, place it in the dish washing station."
        note yeast_overnights.collect { |y| y.id }
      }

      release yeast_overnights
      #delete yeast_overnights

    end

    show {
      title "Wait till cell dry"
      note "Wait till the yeast cells are dried on the plate."
      timer initial: { hours: 0, minutes: 3, seconds: 0 }
    }

    show {
      title "Streak out the plates"
      note "Streak out the plates using either sterile toothpick or pipette tip by moving forward and back on the agar surface with a shallow angle."
      note "For divided plate:"
      image "divided_yeast_plate_streak"
      note "For non divided plate:"
      image "streak_yeast_plate"

    }

    streaked_yeast_plates = glycerol_streaked_yeast_plates + overnight_streaked_yeast_plates

    streaked_yeast_plates.each do |p|
      p.location = "30 C incubator"
      p.save
    end
    release streaked_yeast_plates, interactive: true

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"streaked")
      end
    end

    io_hash[:plate_ids] = streaked_yeast_plates.collect { |x| x.id }
    return { io_hash: io_hash }

  end # main

end # Protocol
