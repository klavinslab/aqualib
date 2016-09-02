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

  def update_batch_matrix batch, num_samples, plate_type
    rows = batch.matrix.length
    columns = batch.matrix[0].length
    batch.matrix = fill_array rows, columns, num_samples, find(:sample, name: "YPAD")[0].id
    batch.save
  end # update_batch_matrix

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
    yeast_overnights = io_hash[:yeast_overnight_ids].collect { |yid| find(:item, id: yid)[0] }

    glycerol_streaked_yeast_plates = []
    overnight_streaked_yeast_plates = []
    
    overall_batches = find(:item, object_type: { name: "Agar Plate Batch" }).map{|b| collection_from b}            
    
    if yeast_glycerol_stocks.length > 0

      yeast_strains_glycerol = yeast_glycerol_stocks.collect { |y| y.sample }
      yeast_strains_overnight = yeast_overnights.collect { |y| y.sample }

      glycerol_streaked_yeast_plates = produce spread yeast_strains_glycerol, "Divided Yeast Plate", 1, num_of_section
      overnight_streaked_yeast_plates = produce spread yeast_strains_overnight, "Divided Yeast Plate", 1, 1

        #detracting from plate batches 
        total_num_plates = glycerol_streaked_yeast_plates.length + overnight_streaked_yeast_plates.length if !glycerol_streaked_yeast_plates.blank? || !overnight_streaked_yeast_plates.blank?
        plate_batch = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0].name == "YPAD" } 
        plate_batch_id = "none" 
        if plate_batch.present?
          plate_batch_id = "#{plate_batch.id}"
          num_plates = plate_batch.num_samples
          update_batch_matrix plate_batch, num_plates - total_num_plates, "YPAD"
          if num_plates < total_num_plates 
            num_left = total_num_plates - num_plates
            plate_batch_two = overall_batches.find{ |b| !b.num_samples.zero? && find(:sample, id: b.matrix[0][0])[0].name == "YPAD"}
            update_batch_matrix plate_batch_two, plate_batch_two.num_samples - num_left, "YPAD" if plate_batch_two.present?
            plate_batch_id = plate_batch_id + ", #{plate_batch_two.id}" if plate_batch_two.present?
          end
        end

      show {
        title "Grab Yeast plates"
          check "Grab #{total_num_plates} of YPAD plates from batch #{plate_batch_id}, label with your name, the date, and the following ids on the top and side of each plate:"
          note glycerol_streaked_yeast_plates.collect { |p| "#{p}"} + overnight_streaked_yeast_plates.collect { |p| "#{p}"}
          check "Divide up each plate with #{num_of_section} sections and mark each with circled #{(1..num_of_section).to_a.join(',')}"
          image "divided_yeast_plate"
      }


      take yeast_glycerol_stocks

      show {
        title "Inoculation from glycerol stock in M80 area"
        check "Go to M80 area, clean out the pipette tip waste box, clean any mess that remains there."
        check "Put on new gloves, and bring a new tip box (green: 10 - 100 µL), a pipettor (10 - 100 µL), and an Eppendorf tube rack to the M80 area."
        check "Grab the plates and go to M80 area to perform inoculation steps in the next pages."
        image "streak_yeast_plate_setup"
      }

      yeast_glycerol_stock_locations = yeast_glycerol_stocks.collect { |y| y.location }

      load_samples_variable_vol( [ "Glycerol Stock id", "Freezer box slot"], [
          yeast_glycerol_stocks.collect { |y| "#{y}" }, yeast_glycerol_stock_locations
        ], glycerol_streaked_yeast_plates ) {
          warning "Be extremely cautious about your sterile technique."
          check "Grab one glycerol stock at a time out of the M80 freezer and place in the tube rack."
          check "Use a sterile 100 µL tip with the pipettor and carefully scrape a half-pea-sized chunk of glycerol stock."
          image "streak_yeast_plate_glycerol_stock"
          check "Place the chunk about 1 cm away from the edge of the yeast plate agar section."
          image "divided_yeast_plate_colony"
        }

      release yeast_glycerol_stocks

    end

    # streak plate for yeast overnights if there is yeast_overnight_ids

    if yeast_overnights.present?

      yeast_overnights = io_hash[:yeast_overnight_ids].collect { |yid| find(:item, id: yid)[0] }
      overnight_streaked_yeast_plates = yeast_overnights.collect { |y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}

      ########TO DELETE
      sample_name = find(:sample, id: 11780)[0].name
      show{
        io_hash[:yeast_selective_plate_types].each do |plate_type|
          note "#{plate_type}"
          note "#{sample_name}"
        end
      }
      plate_batch_id = ""

        io_hash[:yeast_selective_plate_types].each do | plate_type |

          #detracting from plate batches
          total_num_plates = io_hash[:yeast_selective_plate_types].size
          sample_name = find(:sample, id: plate_type)[0].name
          plate_batch = overall_batches.find{ |b| !b.num_samples.zero? && b.matrix[0][0] == plate_type }
          plate_batch_id = "none" 
          if plate_batch.present?
            plate_batch_id = "#{plate_batch.id}"
            num_plates = plate_batch.num_samples
            update_batch_matrix plate_batch, num_plates - 1, "#{sample_name}"
          end
        end

        show {
          note "#{plate_batch_id}"
        }

      show {
        title "Grab yeast plates"
        io_hash[:yeast_selective_plate_types].each_with_index do |plate_type, idx|
          check "Grab one #{plate_type} plate and label with #{overnight_streaked_yeast_plates[idx].id}"  
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
      delete yeast_overnights

    end

    show {
      title "Wait until yeast cells dry"
      note "Wait until the yeast cells are dried on the plate, as in the image below."
      image "streak_yeast_plate_dry"
    }

    show {
      title "Streak out the plates"
      note "Streak out the plates using either sterile toothpick or pipette tip by moving forward and back on the agar surface with a shallow angle."
      image "streak_yeast_plate_video"
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
