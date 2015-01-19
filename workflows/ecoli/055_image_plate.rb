needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the plate ids as a list
      plate_ids: [3798,3797,3799],
      debug_mode: "No",
      image_option: "Yes"
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?  
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash[:image_option] = "Yes" unless io_hash[:image_option]
    plates = io_hash[:plate_ids].collect { |x| find(:item, id: x)[0] }
    show {
      title "Work in the gel room"
      note "You will take images for plates using the gel room camera in this protocol."
      check "Go log into the gel room computer"
      warning "Be sure to wear gloves"
    }
    take plates, interactive: true

    if io_hash[:image_option] == "Yes"
      show {
        title "Imaging guide"
        bullet "Place the agar part of the plate inverted on the transilluminator. Place the camera hood on the transilluminator. Turn on transilluminator by sliding you hand into the hood."
        bullet "Open EOS Utility software on the desktop, and click Camera Settings/Remote Shooting"
        bullet "In the pop up window EOS Rebel T3, make sure the settings are 2'', F4.5, ISO100, Tungsten(light bulb icon), S1."
        bullet "Click Live View shoot, view live plate picture in the Remote Live View Window, physically adjust the camera zoom lens to make sure plate takes up the image field of view."
        bullet "Try Test Shooting, if the test shooting image is not focused or the software shows Focus failure, go to the Remote Live View Window, in the focus section, adjust the focus by clicking the <<< << < > >> >>> buttons until the live image looks focused. Then go back to the EOS Rebel T3 window and click the the black round shutter botton."
      }

      show {
        title "Upload images"
        note "Take a picture for each plate, rename and upload following instructions below."
        plates.each do |p|
          check "Rename the image for plate #{p.id} as plate_#{p.id} and upload here:"
          upload var: "plate_#{p.id}"
          p.save
        end
      }
    end

    colony_number = show {
      title "Estimate colony numbers"
      note "Estimate colony numbers for each plate by eye or using the OpenCFU software and enter in the following."
      warning "Double check if you think there is no colony on the plate, enter 0 for no colony plate."
      plates.each do |p|
        get "number", var: "c#{p.id}", label: "Estimate colony numbers for plate #{p.id}", default: 5
      end
    }

    plates.each do |p|
      p.datum = { num_colony: colony_number[:"c#{p.id}".to_sym] }
      p.save
    end

    # Sort plates into discarded list and stored list based on num_colony
    discarded_plates = plates.select { |p| p.datum[:num_colony] == 0 }
    stored_plates = plates.select { |p| p.datum[:num_colony] > 0 }

    show {
      title "Discard plate that has no colony on it"
      note "Discard the following plates that has no colony on it."
      note discarded_plates.collect{ |p| "#{p}"}
    } if discarded_plates.length > 0

    discarded_plates.each do |p|
      p.mark_as_deleted
      p.save
    end

    location_plate = show {
      title "Parafilm and store plate"
      note "Parafilm the following plates, place them in an available spot in the deli-fridge boxes or stacks, then enter their specific locations. It could be a box like DFP.0 or a location in the stacks like DFP.0.0.20."
      stored_plates.each do |p|
        get "text", var: "c#{p.id}", label: "Enter the location for plate #{p.id}", default: "DFP.0.0.0"
      end
    }

    # update stored plates datum and location

    stored_plates.each do |p|
      p.datum = { num_colony: colony_number[:"c#{p.id}".to_sym] }
      p.location = location_plate[:"c#{p.id}".to_sym]
      p.save
    end

    release plates

    # Set tasks in the io_hash to be plate imaged.
    if io_hash[:task_ids]
      io_hash[:task_ids].each_with_index do |tid,idx|
        task = find(:task, id: tid)[0]
        if task.task_prototype.name == "Gibson Assembly"
          if colony_number[:"c#{plates[idx].id}".to_sym] > 0
            set_task_status(task,"imaged and stored in fridge") 
          elsif colony_number[:"c#{plates[idx].id}".to_sym] == 0
            set_task_status(task,"no colonies")
          end
        else
          set_task_status(task,"imaged and stored in fridge")
        end
      end
    end
    return { io_hash: io_hash }
  end # main
end # Protocol