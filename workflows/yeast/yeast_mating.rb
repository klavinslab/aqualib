needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_mating_strain_ids: [[3104,3099],[1879,3104]],
      yeast_selective_plate_types: ["-TRP,-HIS","SC"],
      user_ids: [20, 20],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # set default values
    io_hash = { yeast_mating_strain_ids: [], debug_mode: "No", yeast_selective_plate_types: [], user_ids: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    raise "Incorrect inputs, yeast_mating_strain_ids size does not match yeast_selective_plate_types size. They need to be one to one correspondence." if io_hash[:yeast_mating_strain_ids].length != io_hash[:yeast_selective_plate_types].length

    show {
      title "Protocol information"
      note "This protocol do yeast matings for the following strain pairs."
      note "#{io_hash[:yeast_mating_strain_ids]}"
    }

    yeast_items_group = io_hash[:yeast_mating_strain_ids].collect { |yids| yids.collect { |yid| find(:sample, id: yid )[0].in("Yeast Glycerol Stock")[0] } }

    yeast_items = yeast_items_group.flatten.uniq

    num = yeast_items.length

    show {
      title "Grab #{num} of 1.5 mL tubes"
      check "Grab #{num} of 1.5 mL tubes, label them with the following ids."
      note yeast_items.collect { |y| y.id }
      check "Add 1 mL of YPAD into each newly labled tube."
    }

    take yeast_items

    inoculation_tab = [["Gylcerol Stock id", "Location", "1.5 mL tube id"]]
    yeast_items.each do |y|
      inoculation_tab.push [ { content: y.id, check: true }, y.location, y.id ]
    end

    show {
      title "Inoculation"
      check "Go to M80 area to perform following inoculation steps."
      check "Grab one glycerol stock at a time out of the M80 freezer."
      check "Use a sterile 100 µL tip with pipettor and vigerously scrape a big chuck of glycerol stock swirl into the 1.5 mL tube following the table below."
      check "Place the glcerol stock immediately back into the freezer after each use."
      table inoculation_tab
      check "You should see all 1.5 mL tubes become cloudy as there are cells inside. If still clear, inoculate more cells from corresponding glycerol stock."
    }

    release yeast_items

    yeast_mated_strains = []

    io_hash[:yeast_mating_strain_ids].each_with_index do |yids, idx|
      y0 = find(:sample, id: yids[0])[0]
      y1 = find(:sample, id: yids[1])[0]
      mated_strain_name = "#{y0.name}, #{y1.name}"
      if find(:sample, name: mated_strain_name)[0]
        y = find(:sample, name: mated_strain_name)[0]
      else
        y = Sample.new
        y.name = mated_strain_name
        y.sample_type_id = y0.sample_type_id
        y.user_id = io_hash[:user_ids][idx]
        y.description = "A diploid strain automatically generated from yeast mating."
        y.project = y0.project
        y.field6 = "diploid"
        y.save
      end
      yeast_mated_strains.push y
    end

    yeast_overnights = yeast_mated_strains.collect { |y| y.make_item "Yeast Overnight Suspension" }

    take yeast_overnights

    yeast_mating_strain_ids_flat = io_hash[:yeast_mating_strain_ids].flatten

    ids_hash = Hash.new(0)
    yeast_mating_strain_ids_flat.each { |v| ids_hash.store(v, ids_hash[v]+1) }

    # build the mating table
    mating_tab = [[ "14 mL tube ids", "First 1.5 mL tube", "Second 1.5 mL tube"]]
    yeast_overnights.each_with_index do |y, idx|
      id0 = yeast_items_group[idx][0]
      id1 = yeast_items_group[idx][1]
      volume0 = [ 100, 1000.0 / ids_hash[id0] ].min.round(0)
      volume1 = [ 100, 1000.0 / ids_hash[id1] ].min.round(0)
      mating_tab.push [ y.id, { content: "#{volume0} µL of #{id0}", check: true }, { content: "#{volume1} µL of #{id1}", check: true } ]
    end

    # prepare 14 mL tubes
    show {
      title "Prepare #{yeast_items_group.length} 14 mL tubes"
      check "Grab #{yeast_items_group.length} of 14 mL tubes, label with following ids"
      note yeast_overnights.collect { |y| y.id }
      check "Add 2 mL of YPAD to each of newly labeled tube."
    }

    # set up yeast matings
    show {
      title "Yeast mating setup"
      check "Vortex all 1.5 mL tubes"
      check "Add contents of 1.5 mL tubes to 14 mL tubes according to the following table."
      table mating_tab
    }

    show {
      title "Incubate"
      check "Place all 14 mL tubes with the following ids into 30 C shaker incubator."
      note yeast_overnights.collect { |y| y.id }
      check "Discard all 1.5 mL tubes."
    }

    move yeast_overnights, "30 C shaker incubator"

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"mating")
      end
    end

    io_hash[:yeast_mated_strain_ids] = yeast_mated_strains.collect { |y| y.id }
    io_hash[:yeast_overnight_ids] = yeast_overnights.collect { |y| y.id }

    return { io_hash: io_hash }
  end

end