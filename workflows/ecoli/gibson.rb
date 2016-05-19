needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol

  include Cloning
  include Standard
  require 'matrix'

  def gibson_vector row
    if row == 0
      return 5.0
    else
      return 0
    end
  end

  def gibson_coefficients row, col, conc_over_length
    if row == 0
      return 1
    elsif col == 0
      return conc_over_length[0]
    elsif row == col
      return -conc_over_length[row]
    else
      return 0
    end
  end

  def ensure_5ul_total volumes
    max = volumes.max
    total = volumes.reduce(:+)
    volumes[volumes.index(max)] = max - (total - 5) if total > 5
    volumes
  end

  def verify_stock_volumes frag_stocks
    need_to_measure = false
    frag_stocks.each do |fs|
      if fs.datum[:volume_verified] != "Yes"
        need_to_measure = true
        break
      end
    end

    if need_to_measure

      fragment_volume = show {
        title "Estimate volume of fragment stock"
        warning "Pause here, don't click through until you entered estimated volume.".upcase
        frag_stocks.each do |fs|
          if fs.datum[:volume_verified] != "Yes"
            get "number", var: "v#{fs.id}", label: "Estimate volume for tube #{fs.id}, normally a number less than 28", default: 28
          end
        end
      }

      # write into datum the verified volumes
      frag_stocks.each do |fs|
        volume = fragment_volume[:"v#{fs.id}".to_sym]
        if volume
          fs.datum = fs.datum.merge({ volume: volume, volume_verified: "Yes" })
          fs.save
        end
      end

    end
  end # verify_stock_volume

  def remove_zero_volumes frag_stocks, not_enough_volume_stocks, replacement_stocks
    frag_stocks.each { |frag|
      if frag.datum[:volume].zero?
      end
    }
  end # remove_zero_volumes

  def find_replacement_stock frag_stock, not_enough_volume_stocks
    i = 1
    replacement = frag_stock.sample.in("Fragment Stock")[i]
    while (not_enough_volume_stocks.include? replacement)
      i += 1
      replacement = frag_stock.sample.in("Fragment Stock")[i]
    end
    replacement
  end # find_replacement_stock

  def update_batch_matrix batch, num_samples
    rows = batch.matrix.length
    columns = batch.matrix[0].length
    batch.matrix = fill_array rows, columns, num_samples, find(:sample, name: "Gibson Aliquot")[0].id
    batch.save
  end # update_batch_matrix

  def update_gibson_batches batch, old_batch, test_batch, used_aliquots
    # used_aliquots functionality to add or subtract aliquots as the users used them
    if test_batch && test_batch.datum[:tested] == "Yes"
      update_batch_matrix test_batch, (test_batch.num_samples - 1)
      used_aliquots -= 1
    end
    if old_batch && old_batch.num_samples > used_aliquots
      update_batch_matrix old_batch, (old_batch.num_samples - used_aliquots)
    else
      if old_batch
        used_aliquots -= old_batch.num_samples
        update_batch_matrix old_batch, 0
        old_batch.mark_as_deleted
        old_batch.save
      end
      update_batch_matrix batch, (batch.num_samples - used_aliquots)
    end
  end

  def arguments
    {
      io_hash: {},
      #Enter the fragment sample ids as array of arrays, eg [[2058,2059],[2060,2061],[2058,2062]]
      fragment_ids: [[4275,2059,2058,3951],[4275,2059],[663,27,28,284],[2059,4275],[3951,3952]],
      #Tell the system if the ids you entered are sample ids or item ids by enter sample or item, sample is the default option in the protocol.
      sample_or_item: "sample",
      #Enter correspoding plasmid id or fragment id for each fragment to be Gibsoned in.
      plasmid_ids: [5985,12648,12980,5205,5986],
      debug_mode: "No",
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # setup default values for io_hash.
    io_hash = { fragment_ids: [], plasmid_ids: [], debug_mode: "No", item_choice_mode: "No" }.merge io_hash

    # Check if inputs are correct
    raise "Incorrect inputs, fragments group size does not match number of plasmids to be built" if io_hash[:fragment_ids].length != io_hash[:plasmid_ids].length

    # Set debug based on debug_mode
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # Find fragment stocks into array of arrays
    if io_hash[:item_choice_mode].downcase == "yes"
      fragment_stocks = io_hash[:fragment_ids].collect{|fids| fids.collect {|fid| choose_sample find(:sample,{id: fid})[0].name, object_type: "Fragment Stock"}}
    else
      fragment_stocks = io_hash[:fragment_ids].collect{|fids| fids.collect {|fid| find(:sample,{id: fid})[0].in("Fragment Stock")[0]}}
    end

    # Rewrite fragment_stocks if the input[:sample_or_item] is specified as item.
    fragment_stocks = io_hash[:fragment_ids].collect{|fids| fids.collect {|fid| find(:item,{id: fid})[0]}} if input[:sample_or_item] == "item"

    # Flatten the fragment_stocks array of arrays
    fragment_stocks_flatten = fragment_stocks.flatten.uniq

    # Sort fragment_stocks_flatten by location for ease of protocol use
    sort_by_location fragment_stocks_flatten

    fragment_stocks_need_length_info = fragment_stocks_flatten.select {|f| f.sample.properties["Length"] == 0}

    show {
      title "Inform user to enter fragment length info"
      note "The following fragment stocks need length info to be entered in the fragment sample page"
      note fragment_stocks_need_length_info.collect { |f| "#{f}" }
      note "Proceed until all the fragment length info entered."
    } if fragment_stocks_need_length_info.length > 0

    predicted_time = time_prediction fragment_stocks_flatten.length, "gibson"

    # Tell the user what we are doing
    show {
      title "Gibson Assembly Information"
      note "In this protocol, you will build #{io_hash[:plasmid_ids].length} plasmids using Gibson Assembly method."
      note "The predicted time needed is #{predicted_time} min."
    }

    # Take fragment stocks
    all_not_enough_volume_stocks = []
    all_replacement_stocks = []
    take fragment_stocks_flatten, interactive: true,  method: "boxes"

    ensure_stock_concentration fragment_stocks_flatten
    verify_stock_volumes fragment_stocks_flatten
    #remove_zero_volumes fragment_stocks_flatten, all_not_enough_volume_stocks, all_replacement_stocks

    aliquot_batches = find(:item, object_type: { name: "Gibson Aliquot Batch" }).sort { |batch1, batch2| batch1.id <=> batch2.id }
    test_batches = aliquot_batches.select { |batch| batch.datum[:tested] == "No" } if io_hash[:plasmid_ids].find { |id| find(:sample, id: id)[0].name == "Test_gibson" }
    test_batch = nil
    if test_batches
      if test_batches.length == 1
        test_batch = collection_from test_batches[0]
      elsif test_batches.length > 1
        test_batch_selection = show {
          title "Select Gibson batch to test"
          select test_batches.map { |batch| batch.id }, var: "batch", label: "Select which Gibson aliquot batch you want to test.", default: 0
        }
        test_batch = collection_from test_batches.find { |batch| batch.id == test_batch_selection[:batch].to_i } if test_batches.any?
      end
      # Send test plasmid and fragment ids to end of list
      test_plasmid_i = io_hash[:plasmid_ids].find_index { |pi| find(:sample, id: pi)[0].name == "Test_gibson" }
      io_hash[:plasmid_ids][test_plasmid_i], io_hash[:plasmid_ids][-1] = io_hash[:plasmid_ids][-1], io_hash[:plasmid_ids][test_plasmid_i]
      io_hash[:task_ids][test_plasmid_i], io_hash[:task_ids][-1] = io_hash[:task_ids][-1], io_hash[:task_ids][test_plasmid_i] if io_hash[:task_ids]
      io_hash[:fragment_ids][test_plasmid_i], io_hash[:fragment_ids][-1] = io_hash[:fragment_ids][-1], io_hash[:fragment_ids][test_plasmid_i]
      fragment_stocks[test_plasmid_i], fragment_stocks[-1] = fragment_stocks[-1], fragment_stocks[test_plasmid_i]
    end

    aliquot_batch = collection_from aliquot_batches.find { |batch| batch.datum[:tested] == "Yes" }
    normal_gibsons = io_hash[:plasmid_ids].length - (test_batch != nil ? 1 : 0)
    enough_aliquots = show {
      title "Take Gibson Aliquots"
      check "Grab an ice block and an aluminum tube rack."
      check "From the M20 freezer, take #{normal_gibsons} Gibson aliquots from the batch labeled #{aliquot_batch}."
      select ["Yes", "No"], var: "selection", label: "Select whether there are enough aliquots in batch #{aliquot_batch} for you to perform the protocol.", default: 0
      check "From the M20 freezer, take 1 Gibson aliquot from the batch labeled #{test_batch}. Set this aliquot in a place such that you will remember that it is the \"test\" aliquot." if test_batch
      check "Spin down aliquots."
      check "Put aliquots in aluminum tube rack."
      image "gibson_aluminum_rack"
    }
    take [aliquot_batch]
    take [test_batch] if test_batch

    old_aliquot_batch = nil
    if enough_aliquots[:selection] == "No"
      new_aliquot_batch = collection_from aliquot_batches.select { |batch| batch.datum[:tested] == "Yes" }[1]
      extra_aliquots_needed = show {
        title "Take more Gibson aliquots"
        check "From the M20 freezer, take as many more aliquots as you need from the batch labeled #{new_aliquot_batch} to have a total of #{normal_gibsons} aliquots."
        get "number", var: "number", label: "Record how many more aliquots you needed from batch #{new_aliquot_batch}.", default: 1
      }
      update_batch_matrix aliquot_batch, (normal_gibsons - extra_aliquots_needed[:number])
      old_aliquot_batch = aliquot_batch
      aliquot_batch = new_aliquot_batch
      take [aliquot_batch]
    end

    # following loop is to show a table of setting up each Gibson reaction to the user
    pre_produced_gibsons = io_hash[:plasmid_ids].collect { |pid| produce new_sample find(:sample,{id: pid})[0].name, of: "Plasmid", as: "Gibson Reaction Result"  }
    gibson_results = []
    unused_aliquots = 0
    not_done_task_ids = []
    no_transformation_task_ids = []
    io_hash[:plasmid_ids].each_with_index do |pid,idx|
      plasmid = find(:sample,{id: pid})[0]
      gibson_result = pre_produced_gibsons[idx]

      prompted_gibson = false
      done_pipetting = false
      using_old_batch = (old_aliquot_batch && gibson_results.length < old_aliquot_batch.num_samples) ? true : false
      
      not_enough_volume_stocks = []
      replacement_stocks = []
      while !done_pipetting && replacement_stocks.length == not_enough_volume_stocks.length
        replacement_stocks.clear
        not_enough_volume_stocks.clear

        # Find usable fragments--fragment stocks that have not been depleted or act as a replacement for depleted stock
        usable_fragments = fragment_stocks[idx].collect { |frag|
          if all_not_enough_volume_stocks.include? frag
            find_replacement_stock frag, all_not_enough_volume_stocks
          else
            frag
          end
        }
        break if usable_fragments.include? nil
        new_fragment_stocks = usable_fragments - Job.find(jid).touches.map { |t| t.item }
        take new_fragment_stocks, interactive: true if new_fragment_stocks.any?
        ensure_stock_concentration usable_fragments

        # Calculate fragment stock volumes for equimolar combination
        verify_stock_volumes usable_fragments
        fragment_volumes = []
        conc_over_length = usable_fragments.collect{|f| f.datum[:concentration].to_f/f.sample.properties["Length"]}
        num = conc_over_length.length
        total_vector = Matrix.build(num, 1) {|row, col| gibson_vector row}
        coefficient_matrix = Matrix.build(num, num) {|row, col| gibson_coefficients row, col, conc_over_length}
        volume_vector = coefficient_matrix.inv * total_vector
        fragment_volumes = volume_vector.each.to_a
        fragment_volumes.collect! { |x| x < 0.2 ? 0.2 : x }
        ensure_5ul_total fragment_volumes

        # Make table for displaying stock volumes to pipette
        tab = []
        usable_fragments.each_with_index do |f,m|
          cell_color = fragment_volumes[m].round(1) < 0.5 ? "#ffe680" : ""
          tab.push([{ content: "#{gibson_result}", style: { background: cell_color } },{ content: "#{f}", style: { background: cell_color } },{ content: fragment_volumes[m].round(1), check: true }])
          new_volume = f.datum[:volume] - fragment_volumes[m].round(1)
          f.datum = f.datum.merge({ volume: new_volume.round(1) })
          f.save
          all_not_enough_volume_stocks.push f if new_volume < 1
        end
        tab.sort! { |r1, r2| r2[2][:content] <=> r1[2][:content] }
        tab.unshift(["Gibson Reaction ids","Fragment Stock ids","Volume (µL)"])

        # Prompt user to pipette stocks
        prompted_gibson = true
        enough_volume = show {
          is_test_gibson = (test_batch && plasmid.name == "Test_gibson") ? true : false
          title "Load #{is_test_gibson ? "Test" : ""} Gibson reaction #{gibson_result}"
          warning "This is a test Gibson. Please make sure to use the right Gibson aliquot." if is_test_gibson
          using_batch = using_old_batch ? old_aliquot_batch : is_test_gibson ? test_batch : aliquot_batch
          check "Relabel an unused Gibson aliquot labeled #{using_batch} as #{gibson_result}."
          note "Make sure the Gibson aliquot is thawed before pipetting."
          warning "Please ensure there is enough volume in each fragment stock to pipette before pipetting."
          
          frags_sorted_by_volume = tab[1..-1].map { |r| r[1][:content] }
          usable_fragments.sort_by { |frag| frags_sorted_by_volume.index("#{frag}") }.each_with_index do |f, i|
            select ["Yes", "No"], var: "#{f.id}", label: "Does #{f} have at least #{tab[i + 1][2][:content]} µL?", default: "Yes"
          end if io_hash[:debug_mode].downcase != "yes"
          warning "Use P2 for volumes of less than 0.5 µL." if tab[1..-1].count { |row| row[2][:content] < 0.5 } > 0
          table tab
        }

        # Deal with not enough volume situation
        usable_fragments.each_with_index do |f, idy|
          if enough_volume[:"#{f.id}".to_sym] == "No"
            not_enough_volume_stocks.push f
            replacement_stock = find_replacement_stock f, (all_not_enough_volume_stocks + [f])
            if replacement_stock != nil && !(all_replacement_stocks.include? replacement_stock)
              replacement_stocks.push replacement_stock
            end
          end
        end
        show {
          not_enough_volume_stocks.uniq!
          title "Discard the following fragment stock#{not_enough_volume_stocks.length == 1 ? "" : "s"}"
          note not_enough_volume_stocks.collect { |f| "#{f}"}
        } if not_enough_volume_stocks.length > 0

        #take replacement_stocks, interactive: true if !replacement_stocks.empty? && replacement_stocks.length == not_enough_volume_stocks.length
        all_replacement_stocks.concat replacement_stocks
        all_not_enough_volume_stocks.concat not_enough_volume_stocks

        # Check if user pipetted everything successfully
        if !(enough_volume.has_value? "No")
          done_pipetting = true
          gibson_results = gibson_results.push gibson_result
          gibson_result.datum = gibson_result.datum.merge({ from: usable_fragments.collect { |f| f.id } })
        end
      end

      # Check if Gibson could not be completed
      if replacement_stocks.length != not_enough_volume_stocks.length || (usable_fragments.include? nil)
        if prompted_gibson
          contaminated_gibson_aliquot = show {
            title "Have you used this Gibson aliquot?"
            select ["Yes", "No"], var: "selection", label: "Have you pipetted any fragments into the Gibson aliquot #{gibson_result}?", default: "No"
          }
          if contaminated_gibson_aliquot[:selection] == "Yes"
            show {
              title "Throw away unfinished Gibson aliquot"
              note "Discard #{gibson_result}"
            }
          else
            show {
              title "Save Gibson aliquot"
              note "Set aside this Gibson aliquot to be returned to the M20 freezer later."
            }
            unused_aliquots += 1
          end
        else
          unused_aliquots += 1
        end
        delete [gibson_result]
        not_done_task_ids.push io_hash[:task_ids][idx] if io_hash[:task_ids]
      elsif test_batch && plasmid.name == "Test_gibson"
        test_batch.datum = test_batch.datum.merge({ tested: "Yes" })
        test_batch.save
      elsif plasmid.properties["Bacterial Marker"].downcase == "n/a"
        #no_transformation_task_ids.push io_hash[:task_ids][idx] if io_hash[:task_ids]
      end
    end

    # Place all reactions in 50 C heat block
    show {
      title "Place on a heat block"
      check "Put all #{gibson_results.length} Gibson Reaction tubes on the 50 C heat block located in the back of bay B7."
      check "<a href='https://www.google.com/search?q=1+hr+timer&oq=1+hr+timer&aqs=chrome..69i57j0l5.1684j0j7&sourceid=chrome&es_sm=122&ie=UTF-8#q=1+hour+timer' target='_blank'>Set a 1 hr timer on Google</a> to remind start the ecoli_transformation protocol to retrieve the Gibson Reaction tubes."
    }

    move gibson_results, "50 C heat block"
    release gibson_results

    unused_aliquots_data = show {
      title "Return unused Gibson aliquots #{unused_aliquots.zero? ? "if you have any" : ""}"
      check "Remove the label from each unused Gibson aliquot."
      check "Return the #{unused_aliquots} unused Gibson aliquot#{unused_aliquots == 1 ? "" : "s"} to the M20 freezer according to #{unused_aliquots == 1 ? "its" : "their"} label numbers."
      get "number", var: "unused_num", label: "Please enter the actual number of unused Gibson aliquots you are returning. Use a negative number if you ended up using more than the protocol asked for.", default: unused_aliquots
    }
    unused_aliquots_data[:unused_num] = 0 if unused_aliquots_data[:unused_num].nil?
    update_gibson_batches aliquot_batch, old_aliquot_batch, test_batch, gibson_results.length + unused_aliquots - unused_aliquots_data[:unused_num]
    release [aliquot_batch]
    release [old_aliquot_batch] if old_aliquot_batch
    release [test_batch] if test_batch

    show {
      title "Return ice block and aluminum tube rack"
      check "Return the ice block and aluminum tube rack."
    }

    all_replacement_stocks.uniq!

    fragment_stocks_to_release = fragment_stocks_flatten - all_not_enough_volume_stocks + all_replacement_stocks

    delete all_not_enough_volume_stocks

    # Release fragment stocks flatten
    release fragment_stocks_to_release, interactive: true,  method: "boxes"

    not_done_task_ids.each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"waiting")
      task.notify "Pushed back to waiting, not enought volume for fragment stocks, new fragment stocks will be made during next fragment construction batch.", job_id: jid
    end

    no_transformation_task_ids.each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"no colonies")
    end

    if io_hash[:task_ids]
      io_hash[:task_ids] = io_hash[:task_ids] - not_done_task_ids - no_transformation_task_ids
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"gibson")
      end
    end
    io_hash[:gibson_result_ids] = gibson_results.collect {|g| g.id}
    return { io_hash: io_hash }
  end

end
