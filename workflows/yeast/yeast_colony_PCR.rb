needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      lysate_stripwell_ids: [13682],
      debug_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { lysate_stripwell_ids: [], debug_mode: "No" }

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    stripwells = io_hash[:lysate_stripwell_ids].collect { |ids| ids.collect { |id| collection_from id } }
    yeast_lysates = io_hash[:yeast_sample_ids].collect { |yid| find(:sample, id: yid)[0]}
    # find QC primers in the yeast strain properties
    forward_primers = yeast_lysates.collect { |y| find(:sample, id: y)[0].properties["QC Primer1"].in("Primer Aliquot")[0] }
    reverse_primers = yeast_lysates.collect { |y| find(:sample, id: y)[0].properties["QC Primer2"].in("Primer Aliquot")[0] }
    primers = forward_primers + reverse_primers
    primers_ids = (primers.collect { |y| y.sample.id }).uniq
    if io_hash[:group] != ("technicians" || "cloning" || "admin")
      primers = primers_ids.collect { |y| choose_sample find(:sample, id: y)[0].name, object_type: "Primer Aliquot" }
    end

    temp = primers.collect {|f| f.sample.properties["T Anneal"]}
    tanneal = temp.min

    take lysate_stripwells, interactive: true
    take primers, interactive: true, method: "boxes"
    # Get phusion enzyme
    phusion_stock_item = choose_sample "Phusion HF Master Mix", take: true
    
    # make new pcr_stripwells for holding all the colony PCR reactions.
    pcr_stripwells = []
    lysate_stripwells.each do |stripwell|
    	pcr_stripwell = produce new_collection "Stripwell", 1, 12
    	pcr_stripwell.matrix = stripwell.matrix
    	pcr_stripwells.push pcr_stripwell
    end

    show {
      title "Prepare Stripwell Tubes"
      pcr_stripwells.each_with_index do |pcr_sw, idx|
        check "Label a new stripwell with the id #{pcr_sw}."
        check "Pipette 3.5 µL of molecular grade water into wells " + pcr_sw.non_empty_string + "."
        check "Transfer 0.5 µL from each well in stripwell #{lysate_stripwells[idx]} to the new stripwell #{pcr_sw}"
        separator
      end
    }

    load_samples( [ "Forward Primer, 0.5 µL", "Reverse Primer, 0.5 µL" ], [
        forward_primers,
        reverse_primers
      ], pcr_stripwells ) {
        warning "Use a fresh pipette tip for each transfer."
      }

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
    # Run the thermocycler
    thermocycler = show {
      title "Start the reactions"
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      separator
      check "Place the stripwells into an available thermal cycler and close the lid."
      get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC1"
      separator
      check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'COLONYPCR'."
      check "Set the anneal temperature to #{tanneal.round(0)}. This is the 3rd temperature."
      check "Set the 4th time (extension time) to be 2 minutes"
      check "Press 'run' and select 10 µL."
    }

    # Set the location of the stripwells to be the name of the thermocycler
    pcr_stripwells.each do |sw|
      sw.move thermocycler[:name]
    end

    # Release the pcr_stripwells silently, since they should stay in the thermocycler
    release pcr_stripwells
    release lysate_stripwells, interactive: true

    release forward_primers + reverse_primers, interactive: true, method: "boxes"

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
