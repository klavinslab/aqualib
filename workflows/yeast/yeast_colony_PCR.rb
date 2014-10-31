needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      lysate_stripwell_ids: [13682],
      yeast_sample_ids: [2866,2866,2866,2866,2866,2866],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    show {
      note "#{io_hash}"
    }
    lysate_stripwells = io_hash[:lysate_stripwell_ids].collect { |sid| collection_from sid }
    yeast_lysates = io_hash[:yeast_sample_ids].collect { |yid| find(:sample, id: yid)[0]}
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    # find QC primers in the yeast strain properties
    forward_primers = yeast_lysates.collect {|y| find(:sample, id: y)[0].properties["QC Primer1"].in("Primer Aliquot")[0]}
    reverse_primers = yeast_lysates.collect {|y| find(:sample, id: y)[0].properties["QC Primer2"].in("Primer Aliquot")[0]}
    fwd_temp = forward_primers.collect {|f| f.sample.properties["T Anneal"]}
    rev_temp = reverse_primers.collect {|r| r.sample.properties["T Anneal"]}
    tanneal = (fwd_temp + rev_temp).min

    take lysate_stripwells, interactive: true
    take forward_primers + reverse_primers, interactive: true, method: "boxes"
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

    # Release the stripwells silently, since they should stay in the thermocycler
    release pcr_stripwells
    release lysate_stripwells, interactive: true

    release forward_primers + reverse_primers, interactive: true, method: "boxes"
    
    io_hash[:pcr_stripwell_ids] = pcr_stripwells.collect { |s| s.id }
    return { io_hash: io_hash }

  end

end
