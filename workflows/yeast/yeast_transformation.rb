needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def debug
    false
  end

  def arguments
    {
      #input should be yeast competent cells and digested plasmids
      yeast_competent_ids: [8437,8431,8426],
      #stripwell that containing digested plasmids
      stripwell_ids: [27779],
      yeast_transformed_strain_ids: [1705,1706,1879]
    }
  end

  def main
  	yeast_competent_cells = input[:yeast_competent_ids].collect {|yid| find(:item, id: yid )[0]}
    yeast_transformation_mixtures = input[:yeast_transformed_strain_ids].collect {|yid| produce new_sample find(:sample, id: yid)[0].name, of: "Yeast Strain", as: "Yeast Transformation Mixture"}
    stripwells = input[:stripwell_ids].collect { |i| collection_from i }

    # show {
    #   title "Testing page"
    #   note(yeast_competent_cells.collect {|x| x.id})
    #   note(yeast_transformation_mixtures.collect {|x| x.id})
    # }

    peg = choose_object "50 percent PEG 3350"
    lioac = choose_object "1.0 M LiOAc"
    ssDNA = choose_object "Salmon Sperm DNA (boiled)"
    take [peg] + [lioac] + [ssDNA], interactive: true

    tab = [["Old ids","New ids"]]
    yeast_competent_cells.each_with_index do |y,idx|
      tab.push([y.id,yeast_transformation_mixtures[idx].id])
    end


    take yeast_competent_cells + stripwells, interactive: true, method: "boxes"

    show {
      title "Re-label all the competent cell tubes"
      table tab
    }

    show {
      title "Yeast transformation preparation"
      check "Spin down all the Yeast Competent Aliquots on table top centrifuge for 20 seconds"
      check "Add 240 µL of 50 percent PEG 3350 into each competent aliquot tube."
      warning "Be careful when pipetting PEG as it is very viscus. Pipette slowly"
      check "Add 36 µL of 1M LiOAc to each tube"
      check "Add 25 µL of Salmon Sperm DNA (boiled) to each tube"
      warning "The order of reagents added is super important for suceess of transformation."
    }

    load_samples(["Yeast Competent Aliquot"],[yeast_competent_cells], stripwells) {
      title "Load 50 µL from each well into corresponding yeast aliquot"
      note "Pieptte 50 µL from each well into corresponding yeast aliquot"
    }

    show {
      title "Vortex strongly and heat shock"
      check "Vortex each tube on highest settings for 45 seconds"
      check "Place all aliquots on 42 C heat block for 15 minutes"
      timer initial: { hours: 0, minutes: 15, seconds: 0}
    }

    show {
      title "Spin down"
      check "Retrive all #{yeast_transformation_mixtures.length} tubes from 42 C heat block."
      check "Spin the tube down for 20 seconds on a small tabletop centrifuge."
      check "Remove all the supernatant carefully with a 1000 µL pipettor (~400 µL total)"
    }

    show {
      title "Resuspend in YPAD"
      check "Add 1 mL of YPAD to the each tube and vortex for 20 seconds"
      check "Grab #{yeast_transformation_mixtures.length} 14 mL tubes, label with #{yeast_transformation_mixtures.collect {|x| x.id}}"
      check "Transfer all contents from each 1.5 mL tube to corresponding 14 mL tube has the same label number"
      check "Place all #{yeast_transformation_mixtures.length} 14 mL tubes into 30 C shaker incubator" 
      check "Discard all #{yeast_transformation_mixtures.length} 1.5 mL tubes"
    }

    release [peg] + [lioac] + [ssDNA], interactive: true
    release yeast_competent_cells + stripwells

    return input.merge yeast_transformation_mixture_ids: yeast_transformation_mixtures.collect {|x| x.id}

  end

end
