needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def debug
    true
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

    show {
      title "Testing page"
      note(yeast_competent_cells.collect {|x| x.id})
      note(yeast_transformation_mixtures.collect {|x| x.id})
    }

    peg = choose_object "50 percent PEG 3350"
    lioac = choose_object "1.0 M LiOAc"
    ssDNA = choose_object "Salmon Sperm DNA (boiled)"
    take [peg] + [lioac] + [ssDNA], interactive: true

    take yeast_competent_cells + stripwells, interactive: true, method: "boxes"

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


    return input.merge yeast_transformation_mixture_ids: yeast_transformation_mixtures.collect {|x| x.id}

  end

end
