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
      debug_mode: "Yes"
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
    plates = io_hash[:plate_ids].collect { |x| find(:item, id: x)[0] }
    show {
      title "Work in the gel room"
      note "You will take images for plates using the gel room camera in this protocol."
      check "Go log into the gel room computer"
      warning "Be sure to wear gloves"
    }
    take plates, interactive: true
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

    colony_number = show {
      title "Estimate colony numbers"
      note "Estimate colony numbers for each plate and enter in the following. Double check if you think there is no colony on the plate, enter 0 for no colony plate."
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
    }

    discarded_plates.each do |p|
      p.mark_as_deleted
      p.save
    end

    location_plate = show {
      title "Parafilm and store plate"
      note "Parafilm the following plates"
      note stored_plates.collect{ |p| "#{p}"}
      note "Store them in an available box in deli-fridge. Enter the label of the box in the following (DFP.0-DFP.7)"
      get "text", var: "x", label: "Enter the label of box you put in", default: "DFP.0"
    }

    # update stored plates datum and location

    stored_plates.each do |p|
      p.datum = { num_colony: colony_number[:"c#{p.id}".to_sym] }
      p.location = location_plate[:x]
      p.save
    end

    release plates

    # Set tasks in the io_hash to be plate imaged.
    if io_hash[:task_ids]
      io_hash[:task_ids].each_with_index do |tid,idx|
        task = find(:task, id: tid)[0]
        set_task_status(task,"imaged and stored in fridge") if colony_number[:"c#{plates[idx].id}".to_sym] > 0
        set_task_status(task,"no colonies") if colony_number[:"c#{plates[idx].id}".to_sym] == 0
      end
    end
    return { io_hash: io_hash }
  end # main
end # Protocol