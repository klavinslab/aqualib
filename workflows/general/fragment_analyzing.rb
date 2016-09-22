needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"
needs "aqualib/lib/frag_an_stripwell_consolidation"

class Protocol

  include Cloning
  include RowNamer
  include StripwellArrayOrganization

  require 'matrix'

  def stripwell_band_verify stripwell, options = {}
    m = stripwell.matrix
    routes = []
    opts = { except: [], plate_ids: [] }.merge options
    opts[:plate_ids].uniq!

    stripwell.matrix.each_with_index do |row, row_idx|
      row.each_with_index do |route, route_idx|
        if route != -1
          s = find(:sample, { id: route })[0]
          qc_lengths = [s.properties["QC_length"]]
          assoc_task = stripwell.datum[:task_id_mapping][route_idx] || -1 if stripwell.datum[:task_id_mapping]
          if assoc_task != -1
            qc_lengths = find(:task, id: assoc_task)[0].simple_spec[:band_lengths]
          end
          qc_lengths = ['N/A'] if qc_lengths == [nil] || qc_lengths == [0] || qc_lengths == [""]
          routes.push({ lane: [row_idx, route_idx], lengths: qc_lengths })
        end
      end
    end

    verify_data = show {
      title "Stripwell #{stripwell}: verify that each lane matches expected size"
      note "Look at the gel image, and match bands with the lengths listed on the side of the gel image."
      note "For more accurate values, select each well under \"analyze\" -> \"electropherogram\" to see peaks for fragments found with labeled lengths."
      note "Select No if there is no band or band does not match expected size,
      select N/A if expected length is N/A and there is a band."
      routes.each_with_index do |route, idx|
        route[:lengths].each_with_index do |length, idx|
          select ["N/A", "Yes", "No"], 
            var: "verify#{route[:lane][0]}_#{route[:lane][1]}_#{idx}", 
            label: "Does gel lane on Row #{route[:lane][0]+1} Col #{route[:lane][1]+1} match the expected length of #{length} bp"
        end
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
                result.push verify_data[:"verify#{i}_#{j}_0".to_sym]
              else
                result = [verify_data[:"verify#{i}_#{j}_0".to_sym]]
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

    # Verification Digest tasks
    stripwell.matrix.each_with_index do |row, row_idx|
      row.each_with_index do |route, route_idx|
        assoc_task = stripwell.datum[:task_id_mapping][route_idx] || -1 if stripwell.datum[:task_id_mapping]
        if assoc_task != -1
          ver_dig_task = find(:task, id: assoc_task)[0]
          band_verifs = ver_dig_task.simple_spec[:band_lengths].map.with_index { |length, idx| verify_data[:"verify#{row_idx}_#{route_idx}_#{idx}"] }
          if band_verifs.uniq == ["Yes"]
            set_task_status ver_dig_task, "correct"
          elsif band_verifs.uniq.length == 1
            set_task_status ver_dig_task, "incorrect"
          else
            set_task_status ver_dig_task, "partial"
          end
        end
      end
    end

  end #gel_band_verify

  def arguments
    {
      io_hash: {},
      gel_band_verify: "Yes",
      stripwell_ids: [51355,15503,37245],
      #stripwell_ids: [10632],
      #yeast_plate_ids: [62825,61775,57979],
      yeast_plate_ids: [],
      #task_ids: [19139,18662,16234],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { debug_mode: "No", gel_band_verify: "No", yeast_plate_ids: [], task_ids: [], group: "admin" }.merge io_hash
    debug_mode = false
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
      debug_mode = true
    end

    verification_digest_task_ids = find(:task, { task_prototype: { name: "Verification Digest" } }).select { |t| t.status == "moved to fridge" }.map { |t| t.id }
    io_hash[:verification_digest_task_ids] = task_choose_limit(verification_digest_task_ids, "Verification Digest")
    io_hash[:verification_digest_task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      stripwell_with_fragment = Item.find { |i| !i.datum[:task_id_mapping].nil? && i.datum[:task_id_mapping].include?(tid) }
      io_hash[:stripwell_ids].push stripwell_with_fragment.id
    end

    io_hash[:stripwell_ids].uniq!

    show {
      title "Fragment analyzing info"
      note "In this protocol, you will gather stripwells of fragments, organize them in the fragment analyzer machine, and upload the analysis results to Aquarium."
    }

    # Move cartridge if necessary
    cartridge = find(:item, object_type: { name: "QX DNA Screening Cartridge" }).find { |c| c.location == "Fragment analyzer" }
    if cartridge
      take [cartridge]
    else
      cartridge = find(:item, object_type: { name: "QX DNA Screening Cartridge" })[0]
      show {
        title "Prepare to insert QX DNA Screening Cartridge into the machine"
        warning "Please keep the cartridge vertical at all times!".upcase
        check "Take the cartridge labeled #{cartridge} from #{cartridge.location} and bring to fragment analyzer."
        check "Remove the cartridge from its packaging and CAREFULLY wipe off any soft tissue debris from the capillary tips using a soft tissue."
        check "Remove the purge cap seal from the back of the cartridge."
        image "frag_an_cartridge_seal_off"
        warning "Do not set down the cartridge when you proceed to the next step."
      }
      show {
        title "Insert QX DNA Screening Cartridge into the machine"
        check "Use a soft tissue to wipe off any gel that may have leaked from the purge port."
        check "Open the cartridge compartment by gently pressing on the door."
        check "Carefully place the cartridge into the fragment analyzer; cartridge description label should face the front and the purge port should face the back of the fragment analyzer."
        check "Insert the smart key into the smart key socket; key can be inserted in either direction."
        image "frag_an_cartridge_and_key"
        check "Close the cartridge compartment door."
        check "Open the ScreenGel software and latch the cartridge by clicking on the \"Latch\" icon."
        check "Grab the purge port seal bag from the bottom drawer beneath the machine, put the seal back on its backing, and return it in the bag to the drawer."
      }
      show {
        title "Wait 30 minutes for the cartridge to equilibrate"
        check "Start a <a href='https://www.google.com/search?q=30+minute+timer&oq=30+minute+timer&aqs=chrome..69i57j69i60.2120j0j7&sourceid=chrome&ie=UTF-8' target='_blank'>30-minute timer on Google</a>, and do not run the fragment analyzer until it finishes."
      }
      take [cartridge]
      cartridge.location = "Fragment analyzer"
      cartridge.save
    end

    # Replace alignment marker if necessary
    alignment_marker = find(:item, sample: { name: "QX Alignment Marker (15bp/5kb)" })[0]
    marker_in_analyzer = find(:item, object_type: { name: "Stripwell" })
                            .find { |s| s.datum[:matrix][0][0] == alignment_marker.sample.id &&
                                        s.location == "Fragment analyzer" }
    marker_needs_replacing = marker_in_analyzer.datum[:begin_date] ? Date.today - (Date.parse marker_in_analyzer.datum[:begin_date]) >= 7 : true
    alignment_marker_stripwell = find(:item, object_type: { name: "Stripwell" })
                                  .find { |s| s.datum[:matrix][0][0] == alignment_marker.sample.id &&
                                              s != marker_in_analyzer }
    if marker_needs_replacing && alignment_marker_stripwell
      show {
        title "Place stripwell #{alignment_marker_stripwell} in buffer array"
        note "Move to the fragment analyzer."
        note "Open ScreenGel software."
        check "Click on the \"Load Position\" icon."
        check "Open the sample door and retrieve the buffer tray."
        warning "Be VERY careful while handling the buffer tray! Buffers can spill."
        check "Discard the current alignment marker stripwell (labeled #{marker_in_analyzer})."
        check "Place the alignment marker stripwell labeled #{alignment_marker_stripwell} in the MARKER 1 position of the buffer array."
        image "make_marker_placement"
        check "Place the buffer tray in the buffer tray holder"
        image "make_marker_tray_holder"
        check "Close the sample door."
      }
      alignment_marker_stripwell.location = "Fragment analyzer"
      alignment_marker_stripwell.datum = alignment_marker_stripwell.datum.merge({ begin_date: Date.today.strftime })
      alignment_marker_stripwell.save
      release [alignment_marker_stripwell]
      delete marker_in_analyzer
    end

    old_stripwells = io_hash[:stripwell_ids].collect { |i| collection_from i }
    take old_stripwells, interactive: true

    extend StripwellArrayOrganization
    # Create the analyzer_wells_array from the given stripwells
    analyzer_wells_array = create_analyzer_wells_array old_stripwells
    # Find stripwell cuts
    stripwell_cuts = find_cuts analyzer_wells_array
    # Create new stripwells based on new configuration
    new_stripwells = stripwells_from_table old_stripwells, analyzer_wells_array
    # Create new_labels, a list of Labels for each of the stripwell pieces
    new_labels = create_labels analyzer_wells_array
    # Create analyzer_well_table, a table formatted for Aquarium with 'A', 'B', 'C', etc. labels instead of stripwell ids and "EB buffer"
    analyzer_well_table = format_table analyzer_wells_array

    show {
      extend StripwellArrayOrganization
      title "Relabel stripwells for stripwell rack arrangement"
      note "Place the stripwells in a green stripwell rack."
      note "To wipe off old labels, use ethanol on a Kimwipe."
      warning "Please follow each step carefully."
      (create_relabel_instructions new_labels, stripwell_cuts).each { |instruction|
        check instruction
      }
      image "frag_an_relabel"
    }

    show {
      title "Uncap stripwells and remove bubbles"
      check "Uncap the stripwells."
      check "Make sure there are no air bubbles in the samples."
      image "frag_an_no_bubbles"
    }

    eb_labels = new_labels.select{ |x| x.stripwell == nil }
    show {
      title "Prepare EB buffer stripwells"
      eb_labels.each { |label|
        check "Make a stripwell of #{label.num_wells} wells, pipette 10 µL of EB buffer into each of its wells."
        check "Label the 1st well \"#{label.label}\"."
      }
    } if eb_labels.length > 0

    show {
      title "Remove empty wells"
      check "Remove all empty wells from the ends of the stripwells. The lengths of the newly-labeled stripwells should be as follows:"
      new_labels.each { |label|
        note "Stripwell #{label.label}: #{label.num_wells} #{label.num_wells != 1 ? "wells" : "well"}"
      }
    }

    show {
      title "Configure stripwells in stripwell rack"
      warning "Keep the stripwells in order AT ALL COSTS!"
      note "Place the stripwells in the stripwell rack according to their labels, as in the following table."
      table analyzer_well_table
      note "Each row with stripwells in it should be completely filled, one well in each of the 12 columns."
      image "frag_an_stripwell_rack_config"
    }

    io_hash[:new_stripwell_ids] = new_stripwells.collect { |i| i.id }

    show {
      title "Move to analyzer"
      note "Carry the stripwells over to the fragment analyzer machine."
      image "frag_an_setup"
    }
    show {
      extend RowNamer
      title "Put stripwells in analyzer"
      warning "Still keep the stripwells in order AT ALL COSTS!"
      check "Transfer the stripwells to the machine tray in exactly the configuration you have them now."
      table analyzer_well_table
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
      title "Select alignment marker"
      check "Under \"Marker\", in the \"Reference Marker\" drop-down, select \"15bp_5kb_022216\". A green dot should appear to the right of the drop-down."
      image "frag_an_select_marker"
    }
    show {
      title "Deselect empty rows"
      check "Under \"Sample selection\", deselect all rows but the first #{new_stripwells.length}.";
      image "frag_an_sample_selection"
      table analyzer_well_table
    }
    show {
      title "Perform final checks before running analysis"
      note "Under \"Run Check\", manually confirm"
      check "Selected rows contain samples."
      check "Alignment marker is loaded (changed every few weeks)."
      image "frag_an_run_check"
    }
    run_data = show {
      title "Run analysis"
      note "If you can't click \"run\", and there is an error that reads, \"The pressure is too low. Replace the nitrogen cylinder or check the external nitrogen source,\" close the software, and reopen it. Then repeat steps 9-13."
      check "Otherwise, click \"run\""
      note "Estimated time is given on the bottom of the screen."
      get "number", var: "runs_left", label: "Enter the number of \"Remaining Runs\" left in this cartridge.", default: 0
      image "frag_an_run"
    }
    while run_data[:runs_left].nil?
      run_data = show {
        title "Enter remaining runs in cartridge"
        warning "Please record how many runs are left in this cartridge."
        get "number", var: "runs_left", label: "Enter the number of \"Remaining Runs\" left in this cartridge.", default: 0
      }
    end
    cartridge.datum = cartridge.datum.merge({ runs: (cartridge.datum[:runs] ? cartridge.datum[:runs] : 0) + new_stripwells.length, runs_left: run_data[:runs_left] })
    cartridge.save
    show {
      title "This cartridge is running low"
      warning "Please notify Michelle that there are fewer than fifty runs left in the current cartridge."
      note "Thanks! :)"
      cartridge.datum = cartridge.datum.merge({ running_low_notif: true })
      cartridge.save
    } if cartridge.datum[:runs_left] < 50 && !cartridge.datum[:running_low_notif]

    job_id = jid # jid not accessible within the scope of show block
    show {
      extend RowNamer
      title "Save PDF and gel images, and upload PDF"
      note "If an error message occurs after the reports were generated, click \"okay.\""
      note "A PDF report is generated. Note that a separate \"gel image\" is generated for each stripwell row."
      check "For each gel image in the PDF, right-click on the image, copy it, and paste it into Paint. Then save to \"Documents/Gel Images\" for each row:"
      new_stripwells.each_with_index.collect { |s, i| note "#{row_name i}: \"stripwell_#{s.id}.JPG\"" }
      check "On the PDF, select \"File\" -> \"Save As\", navigate to \"Documents/PDF Report\", and save the PDF as \"#{Time.now.strftime("%Y-%m-%d")}_#{job_id}\"."
      note "Upload the PDF"
      upload var: "Fragment Analysis Report"
      note "Close the PDF."
    }
    gel_uploads = {}
    new_stripwells.each_with_index do |stripwell, i|
      gel_uploads[stripwell.id] = {}
      # repeat this step if no results is uploaded and debug_mode is no
      repeat_times = 0
      while !gel_uploads[stripwell.id][:stripwell] &&
        !debug_mode
        if repeat_times == 0
          gel_uploads[stripwell.id] = show {
            title "Upload resulting gel image for stripwell #{stripwell.id}"
            note "Upload \"stripwell_#{stripwell.id}.JPG\"."
            upload var: "stripwell"
            image "frag_an_gel_image"
          }
        elsif repeat_times < 4
          gel_uploads[stripwell.id] = show {
            title "Please upload resulting gel image for stripwell #{stripwell.id}"
            note "Upload \"stripwell_#{stripwell.id}.JPG\"."
            upload var: "stripwell"
            image "frag_an_gel_image"
          }
        else
          result = show {
            title "Hmm, well."
            note "Well, it seems like you really don't want to upload the gel image. I don't know why but I'll give up here."
            note "If there is anything wrong with the protocol or the process, please comment after you finish the job. Thanks!"
          }
          break
        end
        repeat_times += 1
      end

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
            task_id = io_hash[:task_ids][io_hash[:yeast_plate_ids].index(p.id)]
            task = find(:task, id: task_id)[0]
            t = Task.new(
                name: "#{p.sample.name}_plate_#{p.id}",
                specification: { "item_ids Yeast Plate|Yeast Overnight Suspension|TB Overnight of Plasmid|Overnight suspension" => [p.id] }.to_json,
                task_prototype_id: tp.id,
                status: "waiting",
                user_id: p.sample.user.id,
                budget_id: task.budget_id)
            t.save
            task.notify "Automatically created a #{task_prototype_html_link 'Glycerol Stock'} #{task_html_link t}.", job_id: jid
            t.notify "Automatically created from #{task_prototype_html_link 'Yeast Strain QC'} #{task_html_link task}.", job_id: jid
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
      new_stripwells.each do |stripwell|
        stripwell_strain_ids = stripwell.matrix
        stripwell_strain_ids.flatten!
        stripwell_strain_ids.delete(-1)
        if (task_yeast_strain_ids & stripwell_strain_ids).any?
          associated_stripwell_ids[stripwell.id] = task_yeast_strain_ids & stripwell_strain_ids
        end
      end
      notifs = []
      show {
        note associated_stripwell_ids.to_json
      } if debug_mode
      associated_stripwell_ids.each do |id, yeast_ids|
        if !debug_mode
          upload_id = gel_uploads[id][:stripwell][0][:id]
          upload_url = Upload.find(upload_id).url
          associated_gel = collection_from id
          gel_matrix = associated_gel.matrix
          yeast_ids_link = yeast_ids.collect { |id| item_or_sample_html_link(id, :sample) + " (location: #{Matrix[*gel_matrix].index(id).collect { |i| i + 1}.join(',')})" }.join(", ")
          image_url = "<a href=#{upload_url} target='_blank'>image</a>".html_safe
          notifs.push "#{'Yeast Strain'.pluralize(yeast_ids.length)} #{yeast_ids_link} associated gel: #{item_or_sample_html_link id, :item} (#{image_url}) is uploaded."
        end
      end
      notifs.each { |notif| task.notify "[Data] #{notif}", job_id: jid }
    end

    # Upload raw data
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
      note new_labels.collect { |label| "#{label.label}" }
    }
    release old_stripwells
    release new_stripwells
    show {
      title "Make sure machine in parked position"
      check "Click \"Processes\" -> \"Parked\" icon."
      image "frag_an_parked"
    }
    show {
      title "Move QX DNA Screening Cartridge to the fridge for the weekend"
      check "Go to R2, and retrieve the blister package labeled #{cartridge}."
      check "Grab the purge port seal from the bottom drawer beneath the fragment analyzer."
      check "Open ScreenGel software and unlatch the cartridge by clicking on the ‘Unlatch’ icon."
      #image "frag_an_unlatch"
      check "Open the cartridge compartment on the fragment analyzer by gently pressing on the door."
      check "Remove the smart key."
      warning "Keep the cartridge vertical at all times!".upcase
      check "Close the purge port with the purge port seal."
      image "frag_an_cartridge_seal_on"
      check "Return the cartridge to the blister package by CAREFULLY inserting the capillary tips into the soft gel."
      check "Close the cartridge compartment door."
      check "Return the purge port seal backing to its plastic bag and place it back in the drawer."
      check "Store the cartridge upright in the door of R2 (B13.120)."
      cartridge.location = "R2 (B13.120)"
      cartridge.save
    } if Time.now.friday?
    release [cartridge]

    (old_stripwells + new_stripwells).each do |stripwell|
      stripwell.mark_as_deleted
    end

    io_hash[:errors] = errors
    return { io_hash: io_hash }
  end # main

end
