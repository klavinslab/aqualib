needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      lysate_stripwell_ids: [32910],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { lysate_stripwell_ids: [], debug_mode: "No" }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # find and take lystae stripwells
    lysate_stripwells = io_hash[:lysate_stripwell_ids].collect { |i| collection_from i }
    take lysate_stripwells, interactive: true

    # find yeast_samples, primer_aliquots, T Anneals
    yeast_sample_ids = lysate_stripwells.collect { |i| i.matrix }
    yeast_samples = yeast_sample_ids.collect do |y|
      y.flatten!.delete(-1)
      y.collect { |y| find(:sample, id: y)[0] }
    end
    forward_primers = yeast_samples.collect { |y| y.collect { |x| x.properties["QC Primer1"].in("Primer Aliquot")[0]} }
    reverse_primers = yeast_samples.collect { |y| y.collect { |x| x.properties["QC Primer2"].in("Primer Aliquot")[0]} }
    tanneals = forward_primers.map.with_index { |pr, idx1| pr.map.with_index { |p, idx2| ( p.sample.properties["T Anneal"] + reverse_primers[idx1][idx2].sample.properties["T Anneal"] ) / 2 } }

    primers = (forward_primers.flatten + reverse_primers.flatten).uniq

    # take primer aliquots
    take primers, interactive: true, method: "boxes"

    # Get phusion enzyme
    phusion_stock_item = choose_sample "Phusion HF Master Mix", take: true

    # build a pcrs hash that pcrs by T Anneal
    pcrs = Hash.new { |h, k| h[k] = { yeast_samples: [], forward_primers: [], reverse_primers: [], lysate_stripwells: [], pcr_stripwells: [], tanneals: [] } }

    lysate_stripwells.each_with_index do |sw, idx|
      if tanneals[idx].min >= 70
        key = :t70
      elsif tanneals[idx].min >= 67
        key = :t67
      else
        key = :t64
      end
      pcrs[key][:yeast_samples].push yeast_samples[idx]
      pcrs[key][:lysate_stripwells].push sw
      pcrs[key][:forward_primers].push forward_primers[idx]
      pcrs[key][:reverse_primers].push reverse_primers[idx]
      pcrs[key][:tanneals].push tanneals[idx].min.round(0)
    end

    # produce pcr stripwells
    pcrs.each do |t, pcr|
      pcr[:lysate_stripwells].each do |sw|
        pcr_stripwell = produce new_collection "Stripwell", 1, 12
        pcr_stripwell.matrix = sw.matrix
        pcr_stripwell.save
        pcr[:pcr_stripwells].push pcr_stripwell
      end
    end
    pcr_stripwells = pcrs.collect { |t, pcr| pcr[:pcr_stripwells] }
    pcr_stripwells.flatten!

    # set up pcr stripwells
    show {
      title "Prepare Stripwell Tubes"
      pcrs.each do |t, pcr|
        pcr[:pcr_stripwells].each_with_index do |sw, idx|
          if sw.num_samples <= 6
            check "Grab a new stripwell with 6 wells and label with the id #{sw}." 
          else
            check "Grab a new stripwell with 12 wells and label with the id #{sw}."
          end
          check "Pipette 3.5 µL of molecular grade water into wells " + sw.non_empty_string + "."
          check "Transfer 0.5 µL from each well in stripwell #{pcr[:lysate_stripwells][idx]} to the new stripwell #{sw}"
        end
      end
      # TODO: Put an image of a labeled stripwell here
    }
  
    # add primers to stripwells
    pcrs.each do |t, pcr|
      pcr[:pcr_stripwells].each_with_index do |sw, idx|
        load_samples( [ "Forward Primer, 0.5 µL", "Reverse Primer, 0.5 µL" ], [
            pcr[:forward_primers][idx],
            pcr[:reverse_primers][idx]
          ], [sw] ) {
            warning "Use a fresh pipette tip for each transfer.".upcase
          }
      end
    end

    # Add master mix
    show {
      title "Add Master Mix"
      pcr_stripwells.each do |sw|
        check "Pipette 5 µL of master mix (item #{phusion_stock_item}) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
      end
      separator
      warning "USE A NEW PIPETTE TIP FOR EACH WELL AND PIPETTE UP AND DOWN TO MIX"
    }

    release [phusion_stock_item], interactive: true, method: "boxes"

    # run the thermocycler
    pcrs.each do |key, pcr|
      tanneal = pcr[:tanneals].inject { |sum, el| sum + el }.to_f / pcr[:tanneals].size
      thermocycler = show {
        title "Start the PCRs at #{tanneal.round(0)} C"
        check "Place the stripwells #{pcr[:pcr_stripwells].collect { |sw| sw.id } } into an available thermal cycler and close the lid."
        get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
        separator
        check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'COLONYPCR'."
        check "Set the anneal temperature to #{tanneal.round(0)}. This is the 3rd temperature."
        check "Set the 4th time (extension time) to be to be 2 minutes."
        check "Press 'run' and select 10 µL."
        #image "thermal_cycler_select"
      }
      pcr[:pcr_stripwells].each do |sw|
        sw.move thermocycler[:name]
      end
    end

    # Release the pcr_stripwells silently, since they should stay in the thermocycler
    release pcr_stripwells

    show {
      title "Clean up"
      note "Discard the following stripwells"
      note "#{lysate_stripwells.collect { |sw| sw.id }}"
      lysate_stripwells.each do |sw|
        sw.mark_as_deleted
      end
    }

    release primers, interactive: true, method: "boxes"

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"pcr")
      end
    end

    io_hash[:stripwell_ids] = pcr_stripwells.collect { |s| s.id }
    return { io_hash: io_hash }

  end

end
