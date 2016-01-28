needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  # pass a list of yeast_strain_ids, return a hash indicates which strain_ids have enough comp cells to transform and which not, also return the comp_cells which contains the comp_cell items and comp_cells_full which contains a list of comp_cell ids and NA to display to the user.
  def yeast_strain_transformation_scan yeast_transformed_strain_ids
    parent_strain_ids = yeast_transformed_strain_ids.collect { |yid| find(:sample, id: yid)[0].properties["Parent"].id }

    ready_ids, not_ready_ids = [], []
    competent_cells = []
    competent_cells_full = [] # an array of competent_cells include nils.
    aliquot_num_hash = Hash.new {|h,k| h[k] = 0 }
    cell_num_hash = Hash.new {|h,k| h[k] = 0 }

    parent_strain_ids.each_with_index do |yid, idx|
      y = find(:sample, id: yid )[0]
      aliquot_num_hash[y.name] += 1
      if y.in("Yeast Competent Aliquot")[ aliquot_num_hash[y.name] - 1 ]
        competent_cell = y.in("Yeast Competent Aliquot")[ aliquot_num_hash[y.name] - 1 ]
      else
        cell_num_hash[y.name] += 1
        competent_cell = y.in("Yeast Competent Cell")[ cell_num_hash[y.name] - 1 ]
      end

      if competent_cell
        competent_cells.push competent_cell
        competent_cells_full.push competent_cell.id
        ready_ids.push yeast_transformed_strain_ids[idx]
      else
        competent_cells_full.push "NA"
        not_ready_ids.push yeast_transformed_strain_ids[idx]
      end

    end

    return {
      ready_ids: ready_ids,
      competent_cells: competent_cells,
      competent_cells_full: competent_cells_full,
      not_ready_ids: not_ready_ids
    }
  end


  def arguments
    {
      io_hash: {},
      plasmid_stock_ids: [9189,11546,11547,34376,6222,9111],
      debug_mode: "Yes",
      yeast_transformed_strain_ids: [11024,11025,11022],
      item_choice_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { stripwell_ids: [], plasmid_stock_ids: [], item_choice_mode: "No", yeast_transformed_strain_ids: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    scan_result = yeast_strain_transformation_scan io_hash[:yeast_transformed_strain_ids]
    io_hash[:yeast_transformed_strain_ids] = scan_result[:ready_ids]
    if scan_result[:not_ready_ids].any?
      not_done_task_ids = []
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        not_transformed_ids = task.simple_spec[:yeast_transformed_strain_ids] & scan_result[:not_ready_ids]
        if not_transformed_ids.any?
          not_transformed_ids_link = not_transformed_ids.collect { |id| item_or_sample_html_link id, :sample }.join(", ")
          task.notify "#{'Yeast Strain'.pluralize(not_transformed_ids.length)} #{not_transformed_ids_link} can not be transformed due to not enough competent cells.", job_id: jid
          if not_transformed_ids == task.simple_spec[:yeast_transformed_strain_ids]
            not_done_task_ids.push tid
            set_task_status(task,"waiting")
            task.notify "Pushed back to waiting due to not enough competent cells.", job_id: jid
            task.save
          else
            notifs = create_new_tasks(not_transformed_ids, task_name: "Yeast Transformation", user_id: task.user.id)[:notifs]
            notifs.each { |notif| task.notify "[Notif] #{notif}", job_id: jid }
          end
        end

      end
      show {
        title "Some transformations can not be done"
        note "Transformation for the following yeast strain can not be performed since there is not enough competent cell."
        note scan_result[:not_ready_ids]
      }
      io_hash[:task_ids] = io_hash[:task_ids] - not_done_task_ids
    end


    io_hash[:plasmid_stock_ids] = io_hash[:yeast_transformed_strain_ids].collect { |yid| choose_stock(find(:sample, id: yid)[0].properties["Integrant"]) }

    if io_hash[:plasmid_stock_ids].length == 0
      show {
        title "No plasmid digestion required"
        note "No plasmid digestion required. Thanks for you effort!"
      }
      return { io_hash: io_hash }
    end

    # sample_stocks means fragmet stock or plasmid stock

    if io_hash[:item_choice_mode].downcase == "yes"
      sample_stocks = io_hash[:plasmid_stock_ids].collect{ |pid| choose_sample find(:item, id: pid )[0].sample.name, object_type: "Plasmid Stock" }
    else
      sample_stocks = io_hash[:plasmid_stock_ids].collect{ |pid| find(:item, id: pid )[0] }
    end

    plasmids = sample_stocks.collect { |p| p.sample }

    take sample_stocks, interactive: true, method: "boxes"

    ensure_stock_concentration sample_stocks

    cut_smart = choose_sample "Cut Smart", take: true

    stripwells = produce spread plasmids, "Stripwell", 1, 12

    show {
      title "Grab an ice block"
      warning "In the following step you will take PmeI enzyme out of the freezer. Make sure the enzyme is kept on ice for the duration of the protocol."
    }

    pmeI = choose_sample "PmeI", take: true

    num_stocks = (sample_stocks.select { |p| p.object_type.name == "Plasmid Stock" }).length
    io_hash[:num_stocks] = num_stocks
    make_master_mix = num_stocks > 1

    water_volume = 42
    buffer_volume = 5
    enzyme_volume = 1
    if make_master_mix
      if num_stocks < 5
        water_volume = water_volume * num_stocks + 21
        buffer_volume = buffer_volume * num_stocks + 2.5
        enzyme_volume = enzyme_volume * num_stocks + 0.5
      elsif num_stocks < 8
        water_volume = water_volume * num_stocks + 42
        buffer_volume = buffer_volume * num_stocks + 5
        enzyme_volume = enzyme_volume * num_stocks + 1
      else
        water_volume = water_volume * num_stocks + 63
        buffer_volume = buffer_volume * num_stocks + 7.5
        enzyme_volume = enzyme_volume * num_stocks + 1.5
      end

      show {
        title "Make Master Mix"
        check "Label a new eppendorf tube MM."
        check "Add #{water_volume.round(1)} µL of water to the tube."
        check "Add #{buffer_volume.round(1)} µL of the cutsmart buffer to the tube."
        check "Add #{enzyme_volume.round(1)} µL of the PmeI to the tube."
        check "Vortex for 5-10 seconds."
        warning "Keep the master mix in an ice block while doing the next steps".upcase
      }
      release [pmeI] + [cut_smart], interactive: true, method: "boxes"
    end

    water_wells = []
    mm_wells = []

    stripwells.each_with_index do |sw, index|
      sw.matrix[0].each_with_index do |x, idx|
        if x > 0
          if find(:sample, id: x)[0].sample_type.name == "Fragment"
            water_wells[index] = [] if !water_wells[index]
            water_wells[index].push (idx + 1)
          elsif find(:sample, id: x)[0].sample_type.name == "Plasmid"
            mm_wells[index] = [] if !mm_wells[index]
            mm_wells[index].push (idx + 1)
          end
        end
      end
    end

    leftover_mix = show {
      title "Prepare Stripwell Tubes"
      stripwells.each_with_index do |sw, index|
        check "Label a new stripwell with the id #{sw}. Write on enough wells to transcribe the full id number."
        check "Pipette 48 µL of water into wells " + water_wells[index].join(", ") if water_wells[index]
        if make_master_mix
          check "Pipette 48 µL from tube MM into wells " + mm_wells[index].join(", ") if mm_wells[index]
          select ["Yes", "No"], var: "leftover", label: "Do you have leftover master mix?", default: 0
        else
          check "Pipette #{water_volume.round(1)} µL of water, #{buffer_volume.round(1)} µL of the cutsmart buffer, and #{enzyme_volume.round(1)} µL of the PmeI into the well." if mm_wells[index]
          check "Carefully flick the well a couple of times to ensure thorough mixing."
        end
      end
    }
    if make_master_mix
      prepare = show {
        if leftover_mix[:leftover] == "Yes"
          title "Record Leftover Master Mix"
          get "number", var: "mix_remaining", label: "Please record the approximate remaining volume (in µL) of mix. Aq devs thank you!", default: 0
        else
          title "Record Extra Master Mix Aliquots"
          get "number", var: "mix_extra_aliquots", label: "Please record how many extra aliquots of master mix you had to prepare. Aq devs thank you!", default: 1
        end
      }
      io_hash[:mix_remaining] = prepare[:mix_remaining]
      io_hash[:mix_extra_aliquots] = prepare[:mix_extra_aliquots]
    else
      release [pmeI] + [cut_smart], interactive: true, method: "boxes"
    end

    sample_stocks_volume_list = []
    sample_stocks.each do |s|
      conc = s.datum[:concentration]
      if conc > 300 && conc < 500
        sample_stocks_volume_list.push 2
      else
        sample_stocks_volume_list.push (1000.0/conc).round(1)
      end
    end

    # set minimal volume to be 0.5 µL
    sample_stocks_volume_list.collect! { |x| x < 0.5 ? 0.5 : x }
    # set maximal volume to be 15 µL
    sample_stocks_volume_list.collect! { |x| x > 15 ? 15 : x }

    sample_stocks_with_volume = sample_stocks.map.with_index { |s,i| sample_stocks_volume_list[i].to_s + " µL of " + s.id.to_s }

    load_samples_variable_vol( ["Sample stock"], [sample_stocks_with_volume], stripwells ) {
      note "Add volume of each sample stock into the stripwell indicated."
      warning "Use a fresh pipette tip for each transfer."
    }

    incubate = show {
      title "Incubate"
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      separator
      check "Place the stripwells into a small green tube holder and then place in 37 C incubator."
      image "put_green_tube_holder_to_incubator"
    }

    stripwells.each do |sw|
      sw.move "37 C incubator"
    end

    release stripwells
    release sample_stocks, interactive: true, method: "boxes"

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"plasmid digested")
      end
    end

    io_hash[:stripwell_ids] = stripwells.collect { |s| s.id }
    return { io_hash: io_hash }

  end

end
