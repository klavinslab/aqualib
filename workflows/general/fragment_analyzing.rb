needs "aqualib/lib/cloning"

class Protocol

  include Cloning
  require 'matrix'

  def stripwell_band_verify col, options = {}
    m = col.matrix
    routes = []
    opts = { except: [], plate_ids: [] }.merge options
    opts[:plate_ids].uniq!

    (0..m.length-1).each do |i|
      (0..m[i].length-1).each do |j|
        if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
          s = find(:sample,{ id: m[i][j] })[0]
          qc_length = s.properties['QC_length']
          qc_length = 'N/A' if qc_length == nil || qc_length == 0 || qc_length == ""
          routes.push lane: [i,j], length: qc_length
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
    def int_to_letter i
      (i + 'A'.ord).chr
    end # int_to_letter
    def row_name i
      "Row #{int_to_letter i}"
    end # row_name
  end # RowName

  module ColorGenerator
    def sample_color_gradient_default seed
      sample_color_gradient 1.11, 1.11, 1.11, 4, 6, 8, 230, 25, seed
    end # sample_color_gradient_default
    def sample_color_gradient frequency1, frequency2, frequency3,
                             phase1, phase2, phase3,
                             center, width, seed
      rgb =  [Math.sin(frequency1 * seed + phase1) * width + center,
              Math.sin(frequency2 * seed + phase2) * width + center,
              Math.sin(frequency3 * seed + phase3) * width + center]
      "#%02x%02x%02x" % rgb
    end # sample_color_gradient
  end # ColorGenerator

  module StripwellArrayOrganization
    def place_stripwells stripwells
      well_array = [[]]
      empty_wells = 12
      current_row = 0
      stripwells.each { |stripwell| # Place stripwells without cutting
        if 12 - well_array[current_row].length >= stripwell.num_samples # Add to existing row
          empty_wells -= stripwell.num_samples
          well_array[current_row].concat(Array.new(stripwell.num_samples) { stripwell })
        else  # Add to new row
          current_row += 1
          empty_wells += 12 - stripwell.num_samples
          well_array.push(Array.new(stripwell.num_samples) { stripwell })
        end
      }
      well_array
    end # place_stripwells

    def consolidate_stripwells well_array
      well_array_min_rows = well_array.flatten.enum_for(:each_slice, 12).to_a.length
      loop_num = 0; # Just in case we encounter an infinite loop
      while well_array.length > well_array_min_rows
        if loop_num > 100
          warning "Organizational error: Sorry, stripwell placement/cutting may not be optimized"
          break
        end
        loop_num += 1

        # Find row with most empty space
        row_lengths = well_array.map { |row| row.length }
        row_lengths.delete_at(-1) # The last row can never be consolidated into
        max_empty_index = row_lengths.index(row_lengths.min)

        # Consolidate below row with this row
        new_rows = well_array[max_empty_index..(max_empty_index + 1)].flatten.enum_for(:each_slice, 12).to_a

        # Replace old two rows with new_rows
        well_array = well_array[0...max_empty_index] + new_rows + well_array[max_empty_index + 2..-1]
      end
      return well_array
    end # consolidate_stripwells

    def create_analyzer_wells_array stripwells
      # Place stripwells in array without cutting
      analyzer_wells_array = place_stripwells stripwells
      # Cut stripwells to minimize rows and cuts
      consolidate_stripwells analyzer_wells_array
    end # create_analyzer_wells_array

    def find_cuts well_array
      cuts = Hash.new
      well_array.each { |row|
        # Record cut (cuts[cut_stripwell] = cut_index)
        last_stripwell = row[-1]
        last_stripwell_well_count = row.count { |stripwell| stripwell == last_stripwell }
        cuts["#{last_stripwell}"] = last_stripwell_well_count if last_stripwell.num_samples > last_stripwell_well_count
      }
      cuts
    end # find_cuts

    def stripwells_from_table stripwells, well_array
      all_wells = stripwells.collect { |stripwell| stripwell.matrix[0].select { |well| well != -1 } }.flatten

      well_array.collect { |row|
        stripwells = row.uniq { |stripwell| stripwell.id }
        if stripwells.length == 1
          all_wells.slice!(0...stripwells[0].num_samples)
          stripwells[0]
        else
          new_stripwell = produce new_collection "Stripwell", 1, 12
          new_stripwell.matrix = [all_wells[0...row.length] + Array.new(12 - row.length) { -1 }]
          all_wells.slice!(0...row.length)
          new_stripwell.save
          new_stripwell
        end
      }
    end # stripwells_from_table

    class Label
      @@num_labels = 0
      @stripwell
      @num_wells
      @second_half
      @label
      def initialize(stripwell, num_wells, second_half = false)
        extend RowNamer
        @stripwell = stripwell
        @num_wells = num_wells
        @second_half = second_half
        @label = int_to_letter @@num_labels
        @@num_labels += 1
      end
      def stripwell
        @stripwell
      end
      def num_wells
        @num_wells
      end
      def second_half
        @second_half
      end
      def label
        @label
      end
      def reset
        @@num_labels = 0
      end
    end # Label

    def create_labels well_array
      # Create list of Labels
      last_stripwell = nil
      labels = well_array.map { |row|
        last_stripwell = nil
        row.each_with_index.map { |stripwell, column|
          if stripwell != last_stripwell
            last_stripwell = stripwell
            label_length = row.count { |s| s == stripwell }
            if label_length < stripwell.num_samples && column == 0 # This is the second half of a stripwell
              Label.new(stripwell, label_length, true)
            else
              Label.new(stripwell, label_length)
            end
          else
            nil
          end
        }.push(row.length < 12 ? Label.new(nil, 12 - row.length) : nil) # EB buffer
        .select { |s| s != nil }
      }.flatten
    end # create_analyzer_well_table

    def format_table well_array
      extend ColorGenerator
      extend RowNamer
      piece_index = 0 # The current stripwell piece (used for int_to_letter and cell color)
      well_array.each_with_index.map { |row, i|
        prev_stripwell = well_array[0][0] # The previous stripwell that was iterated over (for labeling)
        row.concat(Array.new(12 - row.length) { nil }).map { |stripwell|
          if stripwell != prev_stripwell
            prev_stripwell = stripwell
            piece_index += 1
          end
          { check: true, content: (int_to_letter piece_index), style: { background: (sample_color_gradient_default piece_index) } }
        }.unshift({ content: (row_name i), style: { background: "#DDD" } })
      }.unshift([""] + (1..12).to_a.map! { |x| { content: x, style: { background: "#DDD" } } })
      .concat(Array.new(8 - well_array.length) { |i| [{ content: (row_name (i + 2)), style: { background: "#DDD" } }] + Array.new(12) { { content: "", style: { background: "#EEE" } } } } )
    end # format_table

    def create_relabel_instructions labels, stripwell_cuts
      instructions = []
      labels.select{ |x| x.stripwell != nil }.each { |label|
        if !label.second_half
          well_to_label = 1.ordinalize
          instructions.append("Grab stripwell #{label.stripwell} (#{label.stripwell.num_samples} wells). Wipe off the current id. Label the #{well_to_label} well \"#{label.label}\".")
        else
          well_to_label = (stripwell_cuts["#{label.stripwell}"] + 1).ordinalize
          instructions[-1] += " Label the #{well_to_label} well \"#{label.label}\", and cut right before the label."
        end
      }
      instructions
    end # create_relabel_instructions
  end # StripwellArrayOrganization

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

    # verification_digest_task_ids = find(:task, { task_prototype: { name: "Verification Digest" } }).select { |t| t.status == "moved to fridge" }.map { |t| t.id }
    # io_hash[:verification_digest_task_ids] = task_choose_limit(verification_digest_task_ids, "Verification Digest")
    # io_hash[:verification_digest_task_ids].each do |tid|
    #   task = find(:task, id: tid)[0]
    #   stripwells_with_template = collections_with_sample find(:item, id: task.simple_spec[:template_id]).sample.id, "Stripwell"
    #   io_hash[:stripwell_ids].push stripwells_with_template.last.id
    # end

    # show {
    #   note io_hash[:stripwell_ids]
    #   note io_hash[:stripwell_ids].flatten
    # }

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
      check "Under \"Marker\", in the \"Reference Marker\" drop-down, select \"15_bp_5_kb_022216\". A green dot should appear to the right of the drop-down."
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
      warning "Please notify Michelle or Ernesto that there are fewer than fifty runs left in the current cartridge."
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
