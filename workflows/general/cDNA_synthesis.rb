needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "rna_ids Isolated RNA" => [15491,15492,15493],
      "primer_ids Primer" => [4277,4277,4277],
      debug_mode: "Yes"
    }
  end

  def main

    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "Yes", rna_ids: [], primer_ids: [] }.merge io_hash

    # redefine the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    rnas = io_hash[:rna_ids].collect{ |rid| find(:item, { id: rid })[0] }
    rna_samples = rnas.collect { |rna| rna.sample }

    if io_hash[:primer_ids].length > 0
      primers = io_hash[:primer_ids].collect { |id| find(:sample, { id: id })[0].in("Primer Aliquot")[0] }
    end

    take rnas + primers, interactive: true, method: "boxes"

    rnas_need_to_measure = rnas.select { |rna| !rna.datum[:concentration] }
    if rnas_need_to_measure.length > 0
      data = show {
        title "Nanodrop the following RNAs."
        note "Make sure the software is running for Nucleic Acid and change the Sample Type to be RNA-40."
        rnas_need_to_measure.each do |x|
          get "number", var: "c#{x.id}", label: "Go to B9 and nanodrop tube #{x.id}, enter RNA concentration shown in ng/µL on the software in the following", default: 30.2
          get "number", var: "c#{x.id}_quality", label: "Enter 260/280 number for tube #{x.id} in the following", default: 2.0
        end
      }
      rnas_need_to_measure.each do |x|
        x.datum = { concentration: data[:"c#{x.id}".to_sym], unit: "ng/µL", quality_score: data[:"c#{x.id}_quality".to_sym] }
        x.save
      end
    end

    # Set up stripwells
    stripwells = produce spread rna_samples, "Stripwell", 1, 12

    rna_volumes = rnas.collect { |rna| (1000.0/rna.datum[:concentration]).round(1).to_s + " µL of " + rna.id.to_s }
    water_volumes = rna_volumes.collect { |rna_volume| "#{(15-rna_volume.to_f).round(1)} µL"  }
    primer_volumes = primers.collect { |pr| "0.5 µL of #{pr}" }

    show {
      title "Prepare Stripwell Tubes"
      stripwells.each do |sw|
        if sw.num_samples <= 6
          check "Grab a new stripwell with 6 wells and lable with the id #{sw}." 
        else
          check "Grab a new stripwell with 12 wells and lable with the id #{sw}."
        end
      end
      # TODO: Put an image of a labeled stripwell here
    }

    if io_hash[:primer_ids].length > 0
      load_samples_variable_vol( [ "Molecular Grade Water", "RNA", "Primer"], [
          water_volumes,
          rna_volumes,
          primer_volumes
        ], stripwells )
    else
      load_samples_variable_vol( [ "Molecular Grade Water", "RNA"], [
          water_volumes,
          rna_volumes
        ], stripwells )
    end

    release rnas + primers, interactive: true, method: "boxes"

    show {
      title "Add raction mix and reverse transcriptase"
      warning "Use a new pipette tip for each pipetting! Pipette up and down to mix.".upcase
      stripwells.each do |sw|
        check "Pipette 4 µL of 5x iScript reaction mix (item) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
        check "Pipette 1 µL of iScript reverse transcriptase (item) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
        check "Pipette 2 µL of GSP enhancer solution (item) into each of wells " + sw.non_empty_string + " of stripwell #{sw}."
      end
    }

    # Run the thermocycler
    thermocycler = show {
      title "Start the reactions"
      check "Put the cap on each stripwell. Press each one very hard to make sure it is sealed."
      separator
      check "Place the stripwells into an available thermal cycler and close the lid."
      get "text", var: "name", label: "Enter the name of the thermocycler used", default: "T1"
      separator
      if io_hash[:primer_ids].length > 0
        check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'CDNASEL', make sure it has the following settings."
      else
        check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'CDNA', make sure it has the following settings."
        bullet "5 minutes at 25 C"
      end
      bullet "30 minutes at 42 C"
      bullet "5 minutes at 85 C"
      bullet "Hold at 4 C"
      note "If the protocol does not exist on this thermocycler, create one by using above settings."
      check "Press 'Run' and select 20 µL."
      # TODO: image: "thermal_cycler_home"
    }

    yeast_cdnas = []
    stripwells.each do |stripwell|
      yeast_cdnas.concat distribute( stripwell, "Yeast cDNA", interactive: true ) {
        title "Transfer the content from stripwells to new 1.5 mL tubes."
        note "Label the tubes with the id shown above."
      }
    end

    take yeast_cdnas
    release yeast_cdnas, interactive: true, method: "boxes"

  end # main

end # Protocol