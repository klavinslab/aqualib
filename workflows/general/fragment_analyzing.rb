needs "aqualib/lib/cloning"

class Protocol

  include Cloning

  def arguments
    {
      io_hash: {},
      gel_band_verify: "Yes",
      stripwell_ids: [51355,37245],
      yeast_plate_ids: [57317,57208],
      task_ids: [13967,13966],
      debug_mode: "Yes"
    }
  end

  def stripwell_band_verify col, options = {}
    m = col.matrix
    routes = []
    opts = { except: [], plate_ids: [] }.merge options
    opts[:plate_ids].uniq!

    (0..m.length-1).each do |i|
      (0..m[i].length-1).each do |j|
        if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
          s = find(:sample,{ id: m[i][j] })[0]
          length = 0
          if s.description
            description = s.description
            description = " " if description.empty?
            length = description.split('QC_length')[-1].split(':')[-1].to_i
          end
          length = 'N/A' if length == 0
          routes.push lane: [i,j], length: length
        end
      end
    end

    verify_data = show {
      title "Stripwell #{col}: verify that each lane matches expected size"
      note "Look at the gel image, and match bands with the lengths listed on the side of the gel image."
      note "For more accurate values, select each well under \"analyze\" -> \"electropherogram\" to see peaks for fragments found with labeled lengths."
      note "Select No if there is no band or band does not match expected size,
      select N/A if expected length is N/A and there is a band."
      routes.each_with_index do |r,idx|
        select ["N/A", "Yes", "No"], var: "verify#{r[:lane][0]}_#{r[:lane][1]}", label: "Does gel lane on Row #{r[:lane][0]+1} Col #{r[:lane][1]+1} match the expected length of #{r[:length]} bp"
      end
    }

    if opts[:plate_ids].length > 0
      plates = opts[:plate_ids].collect { |id| find(:item, id: id)[0] }
      take plates
      (0..m.length-1).each do |i|
        (0..m[i].length-1).each do |j|
          if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
            s = find(:sample,{ id: m[i][j] })[0]
            plate = (plates.select { |p| p.sample.name == s.name })[0]
            if plate
              result = plate.datum[:QC_result]
              if result
                result.push verify_data[:"verify#{i}_#{j}".to_sym]
              else
                result = [verify_data[:"verify#{i}_#{j}".to_sym]]
              end
              plate.datum = plate.datum.merge({ QC_result: result })
              plate.save
            end
          end
        end
      end
      plates.each do |plate|
        qc_result = plate.datum[:QC_result] || []
        correct_colony_result = qc_result.each_index.select{ |i| qc_result[i] == "Yes" }
        correct_colony_result.map! { |x| x+1 }
        plate.datum = plate.datum.merge({ correct_colony: correct_colony_result })
        plate.save
      end
      release plates
    end

  end #gel_band_verify

  module RowNamer
    def row_name i
      "Row #{(i.to_s.ord - '0'.ord + 'A'.ord).chr}"
    end #row_name
  end #RowName

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "No", gel_band_verify: "No", yeast_plate_ids: [], task_ids: [] }.merge io_hash
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    old_stripwells = io_hash[:stripwell_ids].collect { |i| collection_from i }
    # take old_stripwells, interactive: true

    # To do
    # come up with new_stripwell_ids that contains either old_stripwell_ids or new_stripwell_ids
    # a plan to make new_stripwells
    # new_stripwell = produce new_collection "Stripwell", 1, 12

    io_hash[:new_stripwell_ids] = io_hash[:stripwell_ids]

    stripwells = io_hash[:new_stripwell_ids].collect { |i| collection_from i }
    take stripwells, interactive: true

    show {
      title "Fill empty wells with buffer"
      check "Gather enough stripwell tubes to have 12 tubes total for each row."
      check "Add 10 µL of EB buffer to empty wells."
    }
    show {
      title "Move to analyzer"
      note "Carry the stripwells over to the fragment analyzer machine."
      image "frag_an_setup"
    }
    show {
      title "Remove bubbles"
      check "Make sure there are no air bubbles in the samples."
      check "Uncap the samples."
      image "frag_an_no_bubbles"
    }
    show {
      extend RowNamer
      title "Put stripwells in analyzer"
      check "Arrange the following stripwells on separate rows of the analysis tray starting from the top row:"
      stripwells.each_with_index.collect { |s, i| note "#{row_name i}: #{s}" }
      check "Close the lid on the machine."
      image "frag_an_stripwell_placement"
    }
    show {
      title "Select PhusionPCR"
      note "Click \"Back to Wizard\" if previous data is displayed."
      check "Under \"Process\" -> \"Process Profile\", make sure \"PhusionPCR\" is selected."
      image "frag_an_phusion_pcr"
    }
    show {
      title "Deselect empty rows"
      check "Under \"Sample selection\", deselect all rows that do not have stripwells in them.";
      image "frag_an_sample_selection"
    }
    show {
      title "Final checks before running analysis"
      note "Under \"Run Check\", manually confirm"
      check "Selected rows contain samples."
      check "Alignment marker is loaded (changed every few weeks)."
      image "frag_an_run_check"
    }
    show {
      title "Run analysis"
      check "Click \"run\""
      note "Estimated time is given on the bottom of the screen."
      image "frag_an_run"
    }
    job_id = jid # jid not accessible within the scope of show block
    show {
      extend RowNamer
      title "Save PDF and gel images, and upload PDF"
      note "If an error message occurs after the reports were generated, click \"okay.\""
      note "A PDF report is generated. Note that a separate \"gel image\" is generated for each stripwell row."
      check "For each gel image in the PDF, right-click on the image, copy it, and paste it into Paint. Then save to \"Documents/Gel Images\" for each row:"
      stripwells.each_with_index.collect { |s, i| note "#{row_name i}: \"stripwell_#{s.id}.JPG\"" }
      check "On the PDF, select \"File\" -> \"Save As\", navigate to \"Documents/PDF Report\", and save the PDF as \"#{Time.now.strftime("%Y-%m-%d")}_#{job_id}\"."
      note "Upload the PDF"
      upload var: "Fragment Analysis Report"
      note "Close the PDF."
    }
    gel_uploads = {}
    stripwells.each_with_index do |stripwell, i|
      gel_uploads[stripwell.id] = show {
        title "Upload resulting gel image for stripwell #{stripwell.id}"
        note "Upload \"stripwell_#{stripwell.id}.JPG\"."
        upload var: "stripwell_#{stripwell.id}"
        image "frag_an_gel_image"
      }

      if io_hash[:gel_band_verify].downcase == "yes"
        stripwell_band_verify stripwell, plate_ids: io_hash[:yeast_plate_ids]
      end
    end

    if io_hash[:gel_band_verify].downcase == "yes"
      plates = io_hash[:yeast_plate_ids].collect { |id| find(:item, id: id)[0] }
      plates.each do |p|
        if p.datum[:correct_colony]
          if p.datum[:correct_colony].length > 0
            tp = TaskPrototype.where("name = 'Glycerol Stock'")[0]
            t = Task.new(
                name: "#{p.sample.name}_plate_#{p.id}",
                specification: { "item_ids Yeast Plate|Yeast Overnight Suspension|TB Overnight of Plasmid|Overnight suspension" => [p.id] }.to_json,
                task_prototype_id: tp.id,
                status: "waiting",
                user_id: p.sample.user.id)
            t.save
            t.notify "Automatically created from Yeast Strain QC.", job_id: jid
          end
        end
      end
    end

    errors = []

    io_hash[:task_ids].each do |tid|
      task = find(:task, id:tid)[0]
      set_task_status(task,"gel imaged")
      task_yeast_plate_ids = task.simple_spec[:yeast_plate_ids]
      task_yeast_strain_ids = task_yeast_plate_ids.collect { |id| find(:item, id: id)[0].sample.id }
      associated_stripwell_ids = {}
      stripwells.each do |stripwell|
        stripwell_strain_ids = stripwell.matrix
        stripwell_strain_ids.flatten!
        stripwell_strain_ids.delete(-1)
        if (task_yeast_strain_ids & stripwell_strain_ids).any?
          associated_stripwell_ids[stripwell.id] = task_yeast_strain_ids & stripwell_strain_ids
        end
      end
      notifs = []
      associated_stripwell_ids.each do |id, yeast_ids|
        begin
          upload_id = gel_uploads[id][:stripwell][0][:id]
          upload_url = Upload.find(upload_id).url
          associated_gel = collection_from id
          gel_matrix = associated_gel.matrix
          yeast_ids_link = yeast_ids.collect { |id| item_or_sample_html_link(id, :sample) + " (location: #{Matrix[*gel_matrix].index(id).collect { |i| i + 1}.join(',')})" }.join(", ")
          image_url = "<a href=#{upload_url} target='_blank'>image</a>".html_safe
          notifs.push "#{'Yeast Strain'.pluralize(yeast_ids.length)} #{yeast_ids_link} associated gel: #{item_or_sample_html_link id, :item} (#{image_url}) is uploaded."
        rescue Exception => e
          errors.push e.to_s
        end
      end
      notifs.each { |notif| task.notify "[Data] #{notif}", job_id: jid }
    end


    show {
      title "Prepare to upload resulting analyzer data"
      check "Under \"Analysis\". \"Gel Image\" tab, click \"Select All\"."
      check "Under the \"View\" tab, check \"Show Analysis Parameters\"."
      image "frag_an_select_all"
    }
    show {
      title "Save resulting analyzer data"
      check "Under the \"Report\" tab, click \"Start Report/Export\"."
      note "Wait while the files are generated."
      check "Under \"File\"->\"Open Data Directory\", click \"Export\"."
      check "Copy the following files with today's date, and paste into \"Documents/Raw Data\":"
      note "_Rw"
      note "_Rw.csv"
      note "_Go_150dpi_1"
      note "_Ex_PeakCalling.csv"
      image "frag_an_files_to_upload"
    }
    show {
      title "Upload resulting analyzer data"
      note "Upload the files ending in the following sequences:"
      note "_Rw"
      upload var: "Raw XML"
      note "_Rw.csv"
      upload var: "Raw CSV"
      note "_Go_150dpi_1"
      upload var: "Gel Image"
      note "_Ex_PeakCalling.csv"
      upload var: "Peak Calling CSV"
    }
    show {
      title "Discard stripwells"
      note "Discard the following stripwells:"
      note stripwells.collect { |s| "#{s}" }
    }
    release stripwells
    show {
      title "Make sure machine in parked position"
      check "Click \"Processes\" -> \"Parked\" icon."
      image "frag_an_parked"
    }
    show {
      title "Have a good weekend!"
      note "This will eventually prompt the user to move the cartridge into the fridge"
    } if Time.now.friday?

    stripwells.each do |stripwell|
      stripwell.mark_as_deleted
    end

    io_hash[:errors] = errors
    return { io_hash: io_hash }
  end # main

end
