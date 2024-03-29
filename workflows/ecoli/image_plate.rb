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
      plate_ids: [71427,71428,71429],
      debug_mode: "Yes",
      image_option: "No",
      task_ids: [23567,23568,23569]
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { image_option: "No" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    plates = io_hash[:plate_ids].collect { |x| find(:item, id: x)[0] }
    plates.compact!  # delete empty plates
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
            if x > 0
              get "number", var: "c#{p.id}.#{index+1}", label: "Estimate colony numbers for plate #{p.id}.#{index+1}", default: 5
              select ["normal", "contamination", "lawn"], var: "report#{p.id}.#{index+1}", label: "If plate #{p.id}.#{index+1} is contaminated, choose contamination. If there is a lawn of colonies, choose lawn.", default: 0
            end
          end
        else
          get "number", var: "c#{p.id}", label: "Estimate colony numbers for plate #{p.id}", default: 5
          select ["normal", "contamination", "lawn"], var: "report#{p.id}", label: "If plate #{p.id} is contaminated, choose contamination. If there is a lawn of colonies, choose lawn.", default: 0
        end
      end
    }

    # for plate as a collection, drop the sample if no colony is no it, record the num_colony as the totoal num_colony on the plate collection
    # for plate as a normal item, just record the num_colony in datum.
    plates.each do |p|
      if p.datum[:matrix]
        new_matrix = [[]]
        num_colony = 0
        section_num_colony = []
        section_status = []
        p.datum[:matrix][0].each_with_index do |x, index|
          new_matrix[0][index] = x
          section_num_colony[index] = colony_number[:"c#{p.id}.#{index+1}".to_sym]
          section_status[index] = colony_number[:"report#{p.id}.#{index+1}".to_sym]
          if colony_number[:"c#{p.id}.#{index+1}".to_sym] == 0
            new_matrix[0][index] = -1
          elsif colony_number[:"c#{p.id}.#{index+1}".to_sym]
            num_colony += colony_number[:"c#{p.id}.#{index+1}".to_sym]
          end
        end
        p.datum = (p.datum).merge({ matrix: new_matrix, num_colony: num_colony, section_num_colony: section_num_colony, section_status: section_status })
      else
        p.datum = (p.datum).merge({ num_colony: colony_number[:"c#{p.id}".to_sym], status: colony_number[:"report#{p.id}".to_sym] })
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

    release stored_plates, interactive: true
    release discarded_plates, interactive: false

    # Set tasks in the io_hash to be plate imaged.
    tasks_to_cancel = []
    if io_hash[:task_ids]
      io_hash[:task_ids].each_with_index do |tid,idx|
        task = find(:task, id: tid)[0]

        if ["Gibson Assembly", "Golden Gate Assembly"].include? task.task_prototype.name

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
              # notify the user about plate stored in fridge
              plate = find(:item, id: plate_id)[0]
              task.notify "[Data] #{item_link plate} with num_colony: #{plate.datum[:num_colony]} is produced."

              # automatically submit E. coli QC task if QC Primer 1, QC Primer 2, and QC Fragment Length are filled in
              # OR automatically submit plasmid verification tasks if sequencing_primer_ids are defined in plasmid sample
              qc_primer1 = plate.sample.properties["QC Primer1"]
              qc_primer2 = plate.sample.properties["QC Primer2"]
              qc_length = plate.sample.properties["QC_length"]
              primers = plate.sample.properties["Sequencing Primers"]

              if !([qc_primer1, qc_primer2, qc_length].any? { |prop| prop.nil? })
                num_colony = [colony_number[:"c#{plate_id}".to_sym], 12].min
                tp = TaskPrototype.where("name = 'E coli QC'")[0]
                t = Task.new(
                  name: "#{plate.sample.name}_plate_#{plate.id}", 
                  specification: { 
                    "plate_ids E coli Plate of Plasmid" => [plate.id],
                    "num_colonies" => [num_colony] 
                    }.to_json, 
                  task_prototype_id: tp.id, 
                  status: "waiting", 
                  user_id: plate.sample.user.id, 
                  budget_id: task.budget_id)
                t.save
                task.notify "Automatically created a #{task_prototype_html_link 'E coli QC'} #{task_html_link t}.", job_id: jid
                t.notify "Automatically created from #{task_prototype_html_link task.task_prototype.name} #{task_html_link task}.", job_id: jid
              elsif primers && primers.length > 0
                primer_ids = primers.collect { |p| p.id if p }
                primer_ids.compact!
                
                tp = TaskPrototype.where("name = 'Plasmid Verification'")[0]
                t = Task.new(
                  name: "#{plate.sample.name}_plate_#{plate_id}",
                  specification: { 
                    "plate_ids E coli Plate of Plasmid" => [plate_id], 
                    "num_colonies" => [1], 
                    "primer_ids Primer" => [primer_ids], 
                    "initials" => "" 
                    }.to_json, 
                  task_prototype_id: tp.id, 
                  status: "waiting", 
                  user_id: plate.sample.user.id, 
                  budget_id: task.budget_id)
                t.save
                task.notify "Automatically created a #{task_prototype_html_link 'Plasmid Verification'} #{task_html_link t}.", job_id: jid
                t.notify "Automatically created from #{task_prototype_html_link task.task_prototype.name} #{task_html_link task}.", job_id: jid
              end
            elsif colony_number[:"c#{plate_id}".to_sym] == 0
              set_task_status(task,"no colonies")
            end

          end

        elsif task.task_prototype.name == "Yeast Transformation"
          yeast_ids = task.simple_spec[:yeast_transformed_strain_ids]
          yeast_names = yeast_ids.collect { |id| find(:sample, id: id)[0].name }
          task_stored_plates = []
          stored_plates.each do |plate|
            if yeast_names.include? plate.sample.name
              task_stored_plates.push plate
            end
          end
          if task_stored_plates.any?
            task_stored_plates.each do |p|
              task.notify "[Data] #{item_link p} with num_colony: #{p.datum[:num_colony]} is produced."
              num_colony = p.datum[:num_colony]
              num_colony = num_colony > 2 ? 2 : num_colony
              tp = TaskPrototype.where("name = 'Yeast Strain QC'")[0]
              t = Task.new(name: "#{p.sample.name}_plate_#{p.id}", specification: { "yeast_plate_ids Yeast Plate" => [p.id], "num_colonies" => [num_colony] }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: p.sample.user.id, budget_id: task.budget_id)
              t.save
              task.notify "Automatically created a #{task_prototype_html_link 'Yeast Strain QC'} #{task_html_link t}.", job_id: jid
              t.notify "Automatically created from #{task_prototype_html_link 'Yeast Transformation'} #{task_html_link task}.", job_id: jid
            end
            set_task_status(task,"imaged and stored in fridge")
          else
            set_task_status(task,"no colonies")
          end

        elsif ["Midiprep", "Maxiprep"].include? task.task_prototype.name
          plate_id = io_hash[:plate_ids][io_hash[:task_ids].index(task.id)]
          plate = find(:item, id: plate_id)[0]

          if plate && colony_number[:"c#{plate.id}".to_sym] > 0
            set_task_status(task,"imaged and stored in fridge")
          else
            task.notify "No colonies for #{task_prototype_html_link task.task_prototype.name} #{task_html_link task}.", job_id: jid
            set_task_status(task,"canceled")

            tasks_to_cancel += [task]
          end
        else
          set_task_status(task,"imaged and stored in fridge")
        end

      end # end io_hash[:task_ids].each_with_index do |tid,idx|

      # remove plates and tasks from io_hash (only for Midiprep and Maxiprep if no colonies)
      io_hash[:plate_ids] -= discarded_plates.map { |p| p.id }
      io_hash[:task_ids] -= tasks_to_cancel.map { |t| t.id }

    end  # end if io_hash[:task_ids]

    return { io_hash: io_hash }

  end # main
end # Protocol
