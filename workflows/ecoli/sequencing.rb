needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def select_task_by_plasmid_stock io_hash, stock_ids
      io_hash[:task_ids].select.with_index { |tid, idx| 
                                              seq_task = find(:task, { task_prototype: { name: "Sequencing" }, id: tid })
                                              if seq_task.any?
                                                (stock_ids & seq_task[0].simple_spec[:plasmid_stock_id]).any?
                                              else
                                                task = find(:task, id: tid)[0]
                                                plasmid_ids_from_stocks = stock_ids.map { |sid| find(:item, id: sid)[0].sample.id }
                                                plasmid_ids_from_plates = task.simple_spec[:plate_ids].map { |pid| find(:item, id: pid)[0].sample.id }
                                                (plasmid_ids_from_stocks & plasmid_ids_from_plates).any?
                                              end
                                            }
  end

  def hash_by_sample items
    item_hash = {}
    items.each { |i|
      if item_hash[i.sample.id].nil?
        item_hash[i.sample.id] = [i]
      else
        item_hash[i.sample.id].push(i)
      end
    }
    item_hash
  end

  def total_volumes_by_item items, volumes
    vol_hash = {}
    items.each_with_index { |s, idx|
      if vol_hash[s.id].nil?
        vol_hash[s.id] = volumes[idx]
      else
        vol_hash[s.id] += volumes[idx]
      end
    }
    vol_hash
  end

  def determine_enough_volumes_each_item items, volumes, opts={}
    return [[],[],[]] if items.empty? || volumes.empty?
    options = { check_contam: false }.merge opts

    total_vols_per_item = total_volumes_by_item items, volumes
    verify_data = show {
      title "Verify enough volume of each #{items[0].object_type.name} exists#{options[:check_contam] ? ", or note if contamination is present" : ""}"
      total_vols_per_item.each { |id, v| 
        choices = options[:check_contam] ? ["Yes", "No", "Contamination is present"] : ["Yes", "No"]
        select choices, var: "#{id}", label: "Is there at least #{(v + 5).round(1)} µL of #{id}?", default: 0 
      }
    }

    bools = items.map { |i| verify_data[:"#{i.id}".to_sym] == "Yes" ? true : false }
    [items.select.with_index { |i, idx| bools[idx] },
    items.select.with_index { |i, idx| !bools[idx] },
    bools]
  end

  def arguments
    {
      io_hash: {},
      #plasmid_stock_ids: [15417,15418,15417,73966,73966,15418,15417,73433,15418,15417,15418],
      #primer_ids: [[2575,2054],[2054],[2575,2054],[2575,14429],[14429],[2575,2054],[2575,2054],[14369,14368],[2575,2054],[2575,2054],[2575,2054]],
      plasmid_stock_ids: [73249, 73437, 74270, 74269],
      primer_ids: [[14287, 14288], [14252], [351, 1405], [351, 1405]],
      task_ids: [25343, 25315, 25314],
      sequencing_task_ids: [25341],
      debug_mode: "No",
      group: "technicians"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    io_hash = { task_ids: [], debug_mode: "No", overnight_ids: [], item_choice_mode: "No", sequencing_verification_task_ids: [] }.merge io_hash
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    batch_initials = "MP"

    # turn input plasmid_stock_ids and primer_ids into two corresponding arrays
    plasmid_stock_ids = []
    primer_ids = []

    idx = 0
    io_hash[:primer_ids].each_with_index do |pids|
      unless pids == []
        unless find(:item, id: io_hash[:plasmid_stock_ids][idx])[0].datum[:concentration] == 0
          primer_ids.concat pids
          (1..pids.length).each do
            plasmid_stock_ids.push io_hash[:plasmid_stock_ids][idx]
          end
        end
        idx += 1
      end
    end

    sequencing_tasks_list = find_tasks task_prototype_name: "Sequencing", group: io_hash[:group]
    sequencing_info = task_status sequencing_tasks_list
    io_hash[:sequencing_task_ids] = task_choose_limit(sequencing_info[:ready_ids], "Sequencing")
    io_hash[:task_ids].concat io_hash[:sequencing_task_ids]
    io_hash[:sequencing_task_ids].each do |tid|
      ready_task = find(:task, id: tid)[0]
      ready_task.simple_spec[:primer_ids].each_with_index do |pids,idx|
        stock = find(:item, id: ready_task.simple_spec[:plasmid_stock_id][idx])[0]
        if ["Plasmid", "Fragment"].include?(stock.sample.sample_type.name)
          primer_ids.concat pids
          (1..pids.length).each do
            plasmid_stock_ids.push ready_task.simple_spec[:plasmid_stock_id][idx]
          end
        end
      end
      # show {
      #   note "#{ready_task.spec}"
      # }
    end
    if plasmid_stock_ids.length == 0
      show {
        title "No sequencing needs to run."
        note "Thank you!"
      }
      return { io_hash: io_hash }
    end

    # Cancel any reactions that don't have a corresponding primer stock
    plasmid_stock_ids_without_primer_stocks = plasmid_stock_ids.select.with_index { |pid, idx| find(:sample, id: primer_ids[idx])[0].in("Primer Stock").empty? }.uniq
    plasmid_stock_ids.each_with_index { |pid, idx|
                                        if plasmid_stock_ids_without_primer_stocks.include? pid
                                          plasmid_stock_ids[idx] = nil
                                          primer_ids[idx] = nil
                                        end
                                      }
    plasmid_stock_ids.compact!
    primer_ids.compact!
    no_primer_stock_task_ids = []
    no_primer_stock_task_ids = select_task_by_plasmid_stock io_hash, plasmid_stock_ids_without_primer_stocks if io_hash[:task_ids]

    plasmid_stocks = plasmid_stock_ids.collect{|pid| find(:item, id: pid )[0]}
    # pop up nanodrop page for stocks without concentration entered
    ensure_stock_concentration plasmid_stocks

    # calculate volumes based on Genewiz guide
    plasmid_volume_list = []
    plasmid_stocks.each_with_index do |p, idx|
      length = p.sample.properties["Length"]
      conc = p.datum[:concentration]
      if p.sample.sample_type.name == "Plasmid" || length >= 4000
        if length < 6000
          plasmid_volume_list.push ( 500.0 / conc ).round(1)
        elsif length < 10000
          plasmid_volume_list.push ( 800.0 / conc ).round(1)
        else
          plasmid_volume_list.push ( 1000.0 / conc ).round(1)
        end
      elsif p.sample.sample_type.name == "Fragment"
        if length < 500
          plasmid_volume_list.push (10 / conc).round(1)
        elsif length < 1000
          plasmid_volume_list.push (20 / conc).round(1)
        elsif length < 2000
          plasmid_volume_list.push (40 / conc).round(1)
        elsif length < 4000
          plasmid_volume_list.push (60 / conc).round(1)
        else
          plasmid_volume_list.push (80 / conc).round(1)
        end
      end
    end
    plasmid_volume_list.collect! { |v| ((v/0.2).ceil*0.2).round(1) }
    plasmid_volume_list.collect! { |v| v < 0.5 ? 0.5 : v > 12.5 ? 12.5 : v }
    water_volume_list = plasmid_volume_list.collect { |v| (((12.5-v)/0.2).floor*0.2).round(1) }
    primer_volume_list = primer_ids.collect { |p| 2.5 }

    # Select only the reactions with enough plasmid stock volume
    take plasmid_stocks, interactive: true, method: "boxes"
    plasmid_stocks, not_enough_vol_plasmid_stocks, enough_vol_plasmid_stock_bools = determine_enough_volumes_each_item plasmid_stocks, plasmid_volume_list

    # Release plasmid stocks without enough volume, and queue tasks to be canceled
    release not_enough_vol_plasmid_stocks, interactive: true, method: "boxes"
    not_enough_plasmid_task_ids = []
    not_enough_plasmid_task_ids = select_task_by_plasmid_stock io_hash, not_enough_vol_plasmid_stocks.map { |p| p.id } if io_hash[:task_ids]
    
    if plasmid_stocks.any?
      # Take primer aliquots corresponding to plasmid stocks, and make new ones if they don't exist for given stock
      primer_ids.select!.with_index { |p, idx| enough_vol_plasmid_stock_bools[idx] }
      primer_volume_list.select!.with_index { |p, idx| enough_vol_plasmid_stock_bools[idx] }
      primer_aliquots_diluted_from_stock = dilute_samples primers_need_to_dilute(primer_ids)
      primer_aliquots = primer_ids.collect { |pid| find(:sample, id: pid )[0].in("Primer Aliquot")[0] }
      if io_hash[:item_choice_mode].downcase == "yes"
        primer_aliquots = primer_ids.collect{ |pid| choose_sample find(:sample, id: pid)[0].name, object_type: "Primer Aliquot" }
      end
      take primer_aliquots - primer_aliquots_diluted_from_stock, interactive: true, method: "boxes"

      # Dilute from primer stocks when there isn't enough volume in the existing aliquot
      enough_vol_primer_aliquots, not_enough_vol_primer_aliquots, enough_vol_primer_aliquot_bools = determine_enough_volumes_each_item primer_aliquots, primer_volume_list, check_contam: true
      additional_primer_aliquots = dilute_samples not_enough_vol_primer_aliquots.map { |p| p.sample.id }

      stripwells = produce spread plasmid_stocks, "Stripwell", 1, 12
      show {
        title "Prepare Stripwells for Sequencing Reaction"
        stripwells.each_with_index do |sw,idx|
          if idx < stripwells.length - 1
            check "Grab a stripwell with 12 wells, label the first well with #{batch_initials}#{idx*12+1} and last well with #{batch_initials}#{idx*12+12}"
          else
            number_of_wells = plasmid_stocks.length - idx * 12
            check" Grab a stripwell with #{number_of_wells} wells, label the first well with #{batch_initials}#{idx*12+1} and last well with #{batch_initials}#{plasmid_stocks.length}"
          end
        end
      }

      water_with_volume = water_volume_list.select.with_index { |v, idx| enough_vol_plasmid_stock_bools[idx] }.map { |v| v.to_s + " µL" }
      plasmids_with_volume = plasmid_stocks.map.with_index { |p, idx| plasmid_volume_list[idx].to_s + " µL of " + p.id.to_s }
      primer_aliquot_hash = hash_by_sample primer_aliquots + additional_primer_aliquots
      primers_with_volume = primer_aliquots.map.with_index { |p, idx| primer_volume_list[idx].to_s + " µL of " + 
                                                              primer_aliquot_hash[p.sample.id].uniq.map { |p| p.id.to_s }.join(" or ") }

      load_samples_variable_vol( ["Molecular Grade Water"], [
        water_with_volume,
        ], stripwells,
        { show_together: true, title_appended_text: "with Molecular Grade Water" })
      load_samples_variable_vol( ["Plasmid"], [
        plasmids_with_volume,
        ], stripwells,
        { show_together: true, title_appended_text: "with Plasmid" })
      load_samples_variable_vol( ["Primer"], [
        primers_with_volume
        ], stripwells,
        { show_together: true, title_appended_text: "with Primer" })

      if not_enough_vol_primer_aliquots.any?
        show {
          title "Discard depleted primer aliquots"
          note "Discard the following primer aliquots:"
          note not_enough_vol_primer_aliquots.uniq.map { |p| "#{p}" }.join(", ")
        }
        delete not_enough_vol_primer_aliquots
      end
      release plasmid_stocks + enough_vol_primer_aliquots + additional_primer_aliquots, interactive: true, method: "boxes"

      # create order table for sequencing
      sequencing_tab = [["DNA Name", "DNA Type", "DNA Length", "My Primer Name"]]
      plasmid_stocks.each_with_index do |p,idx|
        if p.sample.sample_type.name == "Plasmid"
          dna_type = "Plasmid"
        elsif p.sample.sample_type.name == "Fragment"
          dna_type = "Purified PCR"
        end
        owner_initials = name_initials(p.sample.user.name)
        sequencing_tab.push ["#{p.id}-" + owner_initials, dna_type, p.sample.properties["Length"], primer_ids[idx]]
      end

      num = primer_ids.length
      genewiz = show {
        title "Create a Genewiz order"
        check "Go the <a href='https://clims3.genewiz.com/default.aspx' target='_blank'>GENEWIZ website</a>, log in with lab account (Username: mnparks@uw.edu, password is the lab general password)."
        check "Click Create Sequencing Order, choose Same Day, Online Form, Pre-Mixed, #{num} samples, then Create New Form"
        check "Enter DNA Name and My Primer Name according to the following table, choose DNA Type to be Plasmid"
        table sequencing_tab
        check "Click Save & Next, Review the form and click Next Step"
        check "Enter Quotation Number MS0721101, click Next Step"
        check "Print out the form and enter the Genewiz tracking number below."
        get "text", var: "tracking_num", label: "Enter the Genewiz tracking number", default: "10-277155539"
      }

      order_date = Time.now.strftime("%-m/%-d/%y %I:%M:%S %p")

      show {
        title "Put all stripwells in the Genewiz dropbox"
        check "Cap all of the stripwells."
        check "Wrap the stripwells in parafilm."
        check "Put the stripwells into a zip-lock bag along with the printed Genewiz order form."
        check "Ensure that the bag is sealed, and put it into the Genewiz dropbox."
      }
      stripwells.each do |sw|
        sw.mark_as_deleted
        sw.save
      end
      release stripwells
    else 
      show {
        title "No sequencing needs to run"
        note "Thank you!"
      }
    end

    no_primer_stock_task_ids.each { |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"canceled")
      
      primers_to_order = task.simple_spec[:primer_ids].flatten.map { |pid| find(:sample, id: pid)[0] }.select { |p| p.in("Primer Stock").empty? }
      primers_to_order_names = primers_to_order.map { |p| p.name }.join(", ")
      tp = TaskPrototype.where("name = 'Primer Order'")[0]
      show {
        title "task #{t.name} stuff"
        note "#{primers_to_order_names}_primer_order"
        note { "primer_ids Primer" => primers_to_order.map { |p| p.id } }.to_json
        note tp.id
        note primers_to_order[0].user.id
        note task.budget_id
      }
      t = Task.new(name: "#{primers_to_order_names}_primer_order", specification: { "primer_ids Primer" => primers_to_order.map { |p| p.id } }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: primers_to_order[0].user.id, budget_id: task.budget_id)
      t.save
      t.notify "Automatically created from #{task_prototype_html_link task.task_prototype.name} #{task_html_link task}.", job_id: jid
      task.notify "Task canceled. The necessary primer stocks for the reaction were unavailable. A #{task_prototype_html_link 'Primer Order'} task #{task_html_link t} has been automatically submitted.", job_id: jid
    }
    not_enough_plasmid_task_ids.each { |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task,"canceled")
      task.notify "Task canceled. Not enough plasmid stock was present to send to sequencing.", job_id: jid
    }
    io_hash[:task_ids] = io_hash[:task_ids] - no_primer_stock_task_ids - not_enough_plasmid_task_ids

    io_hash[:overnight_ids].each_with_index do |overnight_id, idx|
      overnight = find(:item, id: overnight_id)[0]
      plate_id = overnight.datum[:from].to_i
      parent_task = nil;
      if io_hash[:task_ids]
        io_hash[:task_ids].each do |tid|
          task = find(:task, id: tid)[0]
          if (task.simple_spec[:plate_ids]) && (task.simple_spec[:plate_ids].include? plate_id)
            parent_task = task
          end
        end
      end
      if parent_task
        plasmid_stock = find(:item, id: io_hash[:plasmid_stock_ids][idx])[0]
        tp = TaskPrototype.where("name = 'Sequencing Verification'")[0]
        t = Task.new(name: "#{plasmid_stock.sample.name}_plasmid_stock_#{plasmid_stock.id}", specification: { "plasmid_stock_ids Plasmid Stock" => [ plasmid_stock.id ], "overnight_ids TB Overnight of Plasmid" => [ overnight.id ] }.to_json, task_prototype_id: tp.id, status: "waiting", user_id: overnight.sample.user.id, budget_id: parent_task.budget_id)
        t.save
        t.notify "Automatically created from Plasmid Verification.", job_id: jid
        io_hash[:sequencing_verification_task_ids].push t.id
      end
    end

    # Set tasks in the io_hash to be "send to sequencing"
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"send to sequencing")
      end
    end

    # Return all info
    io_hash[:tracking_num] = genewiz[:tracking_num] if genewiz
    io_hash[:order_date] = order_date if order_date
    return { io_hash: io_hash }

  end # main
end # Protocol