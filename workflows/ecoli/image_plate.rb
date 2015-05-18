needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"
require 'json'

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the plate ids as a list
      plate_ids: [35004,35005],
      debug_mode: "Yes",
      image_option: "No",
      task_ids: []
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { image_option: "Yes" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    plates = io_hash[:plate_ids].collect { |x| find(:item, id: x)[0] }
    take plates, interactive: true

    if io_hash[:image_option] == "Yes"
      show {
        title "Work in the gel room"
        note "You will take images for plates using the gel room camera in this protocol."
        check "Go log into the gel room computer"
        warning "Be sure to wear gloves!"
      }

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
        end
      }
    end

    colony_number = show {
      title "Estimate colony numbers"
      note "Estimate colony numbers for each plate by eye or using the OpenCFU software and enter in the following."
      warning "Double check if you think there is no colony on the plate, enter 0 for no colony plate."
      plates.each do |p|
        # deal with when p is a collection with matrix defined. Assume all the plates are defined as 1xn dimension
        if p.datum[:matrix]
          p.datum[:matrix][0].each_with_index do |x, index|
            get "number", var: "c#{p.id}.#{index+1}", label: "Estimate colony numbers for plate #{p.id}.#{index+1}", default: 5 if x > 0
          end
        else
          get "number", var: "c#{p.id}", label: "Estimate colony numbers for plate #{p.id}", default: 5
        end
      end
    }

    # for plate as a collection, drop the sample if no colony is no it, record the num_colony as the totoal num_colony on the plate collection
    # for plate as a normal item, just record the num_colony in datum.
    plates.each do |p|
      if p.datum[:matrix]
        new_matrix = [[]]
        num_colony = 0
        p.datum[:matrix][0].each_with_index do |x, index|
          new_matrix[0][index] = x
          if colony_number[:"c#{p.id}.#{index+1}".to_sym] == 0
            new_matrix[0][index] = -1
            show {
              note colony_number[:"c#{p.id}.#{index+1}".to_sym]
              note new_matrix
            }
          elsif colony_number[:"c#{p.id}.#{index+1}".to_sym]
            num_colony += colony_number[:"c#{p.id}.#{index+1}".to_sym]
          end
        end
        p.datum = (p.datum).merge({ matrix: new_matrix, num_colony: num_colony })
      else
        p.datum = (p.datum).merge({ num_colony: colony_number[:"c#{p.id}".to_sym] })
      end
      p.save
    end

    # Sort plates into discarded list and stored list based on num_colony
    discarded_plates = plates.select { |p| p.datum[:num_colony] == 0 }
    stored_plates = plates.select { |p| p.datum[:num_colony] != 0 }

    show {
      title "Discard plate that has no colony on it"
      note "Discard the following plates that has no colony on it."
      note discarded_plates.collect{ |p| "#{p}"}
    } if discarded_plates.length > 0

    discarded_plates.each do |p|
      p.mark_as_deleted
      p.save
    end

    show {
      title "Write id and parafilm plate(s)"
      note "Perform the steps to the following plates."
      note stored_plates.collect { |p| "#{p}" }
      check "Write the item id number on the side of the plate if it does not have one on the side."
      note "This will help when you later retrieve plates from the fridge."
      check "Parafilm each one."
    }

    # update stored plates datum and location

    stored_plates.each do |p|
      p.store
      p.reload
    end

    release plates, interactive: true

    # Set tasks in the io_hash to be plate imaged.
    if io_hash[:task_ids]
      io_hash[:task_ids].each_with_index do |tid,idx|
        task = find(:task, id: tid)[0]

        if task.task_prototype.name == "Gibson Assembly"

          plasmid_id = task.simple_spec[:plasmid]
          plasmid_name = find(:sample, id: plasmid_id)[0].name
          plate_id = 0
          plates.each do |plate|
            if plate.sample.name == plasmid_name
              plate_id = plate.id
            end
          end

          if plate_id > 0

            if colony_number[:"c#{plate_id}".to_sym] > 0
              set_task_status(task,"imaged and stored in fridge")
              # automatically submit plasmid verification tasks if sequencing_primer_ids are defined in plasmid sample
              plate = find(:item, id: plate_id)[0]
              primer_ids_str = plate.sample.properties["Sequencing_primer_ids"]
              if primer_ids_str
                primer_ids = primer_ids_str.split(",").map { |s| s.to_i }
                if primer_ids.all? { |i| i != 0 }
                  num_colony = colony_number[:"c#{plates[idx].id}".to_sym]
                  num_colony = num_colony > 2 ? 2 : num_colony
                  tp = TaskPrototype.where("name = 'Plasmid Verification'")[0]
                  t = Task.new(name: "#{plate.sample.name}_plate_#{plate_id}", specification: { "plate_ids E coli Plate of Plasmid" => [plate_id], "num_colonies" => [num_colony], "primer_ids Primer" => [primer_ids], "initials" => "" }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: plate.sample.user.id)
                  t.save
                  t.notify "Automatically created from Gibson Assembly.", job_id: jid
                end
              end
            elsif colony_number[:"c#{plate_id}".to_sym] == 0
              set_task_status(task,"no colonies")
            end

          end

        elsif task.task_prototype.name == "Yeast Transformation"
          stored_plates.each do |p|
            num_colony = p.datum[:num_colony]
            num_colony = num_colony > 3 ? 3 : num_colony
            tp = TaskPrototype.where("name = 'Yeast Strain QC'")[0]
            t = Task.new(name: "#{p.sample.name}_plate_#{p.id}", specification: { "yeast_plate_ids Yeast Plate" => [p.id], "num_colonies" => [num_colony] }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: p.sample.user.id)
            t.save
            t.notify "Automatically created from Yeast Transformation.", job_id: jid
          end
          set_task_status(task,"imaged and stored in fridge")

        else
          set_task_status(task,"imaged and stored in fridge")
        end

      end # end io_hash[:task_ids].each_with_index do |tid,idx|

    end  # end if io_hash[:task_ids]

    return { io_hash: io_hash }

  end # main
end # Protocol
