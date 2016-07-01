needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

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

  def determine_enough_volumes_each_item items, volumes
    total_vols_per_item = total_volumes_by_item items, volumes
    verify_data = show {
      title "Verify enough volume of each #{items[0].object_type.name} exists"
      total_vols_per_item.each { |id, v| 
        select ["Yes", "No"], var: "#{id}", label: "Is there at least #{(v + 5).round(1)} µL of #{id}?", default: 0
      }
    }

    # show {
    #   note "verify_data"
    #   note verify_data.map { |id, sel| "#{id}: #{sel}" }
    #   note "enough"
    #   note enough_vol_stocks.map { |s| s.id }
    #   note "not enough"
    #   note not_enough_vol_stocks.map { |s| s.id }
    # }

    items.map { |s| verify_data[:"#{s.id}".to_sym] == "Yes" ? true : false }
  end

  def arguments
    {
      io_hash: {},
      plasmid_stock_ids: [15417,15418,15417,15418,15417,15418,15417,15418],
      primer_ids: [[2575,2054],[2054],[2575,2054],[2575,2054],[2575,2054],[2575,2054],[2575,2054],[2575,2054]],
      debug_mode: "Yes",
      group: "yang"
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

    plasmid_stocks = plasmid_stock_ids.collect{|pid| find(:item, id: pid )[0]}
    # pop up nanodrop page for stocks without concentration entered
    ensure_stock_concentration plasmid_stocks
    
    diluted_primer_aliquots = dilute_samples primers_need_to_dilute(primer_ids)
    primer_aliquots = (primer_ids).collect{ |pid| find(:sample, id: pid )[0].in("Primer Aliquot")[0] }
    if io_hash[:item_choice_mode].downcase == "yes"
      primer_aliquots = primer_ids.collect{ |pid| choose_sample find(:sample, id: pid)[0].name, object_type: "Primer Aliquot" }
    end
    take plasmid_stocks + (primer_aliquots - diluted_primer_aliquots), interactive: true, method: "boxes"
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
    primer_volume_list = primer_aliquots.collect { |p| 2.5 }

    water_with_volume = water_volume_list.map { |v| v.to_s + " µL" }
    plasmids_with_volume = plasmid_stock_ids.map.with_index { |pid, i| plasmid_volume_list[i].to_s + " µL of " + pid.to_s }
    primers_with_volume = primer_aliquots.map.with_index { |p, i| primer_volume_list[i].to_s + " µL of " + p.id.to_s }

    enough_plasmid_vol_bools = determine_enough_volumes_each_item plasmid_stocks, plasmid_volume_list
    enough_vol_primer_aliquots = primer_aliquots.select.with_index { |p, idx| enough_plasmid_vol_bools[idx] }
    enough_vol_primer_vols = primer_volume_list.select.with_index { |p, idx| enough_plasmid_vol_bools[idx] }
    enough_primer_vol_bools = determine_enough_volumes_each_item enough_vol_primer_aliquots, enough_vol_primer_vols

    show {
      note enough_plasmid_vol_bools
      note enough_primer_vol_bools
    }

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

    load_samples_variable_vol( ["Molecular Grade Water"], [
      water_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Molecular Grade Water" } )
    load_samples_variable_vol( ["Plasmid"], [
      plasmids_with_volume,
      ], stripwells,
      { show_together: true, title_appended_text: "with Plasmid" } )
    load_samples_variable_vol( ["Primer"], [
      primers_with_volume
      ], stripwells,
      { show_together: true, title_appended_text: "with Primer" } )

    release plasmid_stocks + primer_aliquots, interactive: true, method: "boxes"
    stripwells.each do |sw|
      sw.mark_as_deleted
      sw.save
    end

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
    io_hash[:tracking_num] = genewiz[:tracking_num]
    io_hash[:order_date] = order_date
    return { io_hash: io_hash }

  end # main
end # Protocol
