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
      io_hash: {},
      #input should be yeast competent cells and digested plasmids
      "yeast_competent_ids Yeast Competent Aliquot" => [8437,8431,8426,27794,27788,27782],
      #stripwell that containing digested plasmids
      stripwell_ids: [27779],
      yeast_transformed_strain_ids: [1705,1706,1879,1879,1879,1706],
      plasmid_ids: [27507,27508,27509,1543,3859,28030]
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    if io_hash[:debug_mode] == "Yes"
      def debug
        true
      end
    end
  	yeast_competent_cells = io_hash[:yeast_competent_ids].collect {|yid| find(:item, id: yid )[0]}
    yeast_transformation_mixtures = io_hash[:yeast_transformed_strain_ids].collect {|yid| produce new_sample find(:sample, id: yid)[0].name, of: "Yeast Strain", as: "Yeast Transformation Mixture"}
    stripwells = io_hash[:stripwell_ids].collect { |i| collection_from i }

    # show {
    #   title "Testing page"
    #   note(yeast_competent_cells.collect {|x| x.id})
    #   note(yeast_transformation_mixtures.collect {|x| x.id})
    # }

    peg = choose_object "50 percent PEG 3350"
    lioac = choose_object "1.0 M LiOAc"
    ssDNA = choose_object "Salmon Sperm DNA (boiled)"
    take [peg] + [lioac] + [ssDNA], interactive: true

    tab = [["Old id","New id"]]
    yeast_competent_cells.each_with_index do |y,idx|
      tab.push([y.id,yeast_transformation_mixtures[idx].id])
    end


    take yeast_competent_cells + stripwells, interactive: true, method: "boxes"

    show {
      title "Re-label all the competent cell tubes"
      table tab.transpose
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

    yeast_transformation_mixtures_markers = Hash.new {|h,k| h[k] = [] }
    yeast_markers = io_hash[:plasmid_ids].collect {|pid| find(:item, id: pid )[0].sample.properties["Yeast Marker"].downcase[0,3]}
    yeast_transformation_mixtures.each_with_index do |y,idx|
      yeast_markers.uniq.each do |mk|
        yeast_transformation_mixtures_markers[mk].push y if yeast_markers[idx] == mk
      end
    end

    yeast_plates = []
    yeast_transformation_mixtures_markers.each do |key, mixtures|
      if key == "kan"
        show {
          title "Resuspend in YPAD"
          check "Grab #{"tube".pluralize(mixtures.length)} with id #{(mixtures.collect {|x| x.id}).join(", ")}"
          check "Add 1 mL of YPAD to the each tube and vortex for 20 seconds"
          check "Grab #{mixtures.length} 14 mL #{"tube".pluralize(mixtures.length)} , label with #{(mixtures.collect {|x| x.id}).join(", ")}"
          check "Transfer all contents from each 1.5 mL tube to corresponding 14 mL tube that has the same label number"
          check "Place all #{mixtures.length} 14 mL #{"tube".pluralize(mixtures.length)}  into 30 C shaker incubator" 
          check "Discard all #{mixtures.length} empty 1.5 mL #{"tube".pluralize(mixtures.length)} "
        }
        mixtures.each do |y|
          y.location = "30 C shaker incubator"
          y.save
        end
        release mixtures
      else
        yeast_plates_sub = mixtures.collect {|v| produce new_sample v.sample.name, of: "Yeast Strain", as: "Yeast Plate"}
        yeast_plates += yeast_plates_sub
        tab = [["Tube id","Plate id"]]
        mixtures.each_with_index do |y,idx|
          tab.push([y.id,yeast_plates_sub[idx].id])
        end
        show {
          title "Take #{mixtures.length} -#{key.upcase} #{"plate".pluralize(mixtures.length)}"
          check "Grab #{mixtures.length} -#{key.upcase} #{"plate".pluralize(mixtures.length)} from B0.110"
          check "Label each plate with #{(yeast_plates_sub.collect {|x| x.id}).join(", ")}"
          check "Grab #{"tube".pluralize(mixtures.length)} with id #{(mixtures.collect {|x| x.id}).join(", ")}"
          check "Add 600 µL of MG water to the each tube and vortex for 20 seconds"
        }
        show {
          title "Plating"
          check "Pour 3-10 sterile beads to each plate"
          check "Transfer 200 µL from each 1.5 mL tube to corresponding -#{key.upcase} plate using the following table"
          table tab.transpose
          check "Shake the plate to spread the sample over the surface until dry."
          check "Pour the beads into a waste bead container"
          check "Discard above 1.5 mL tubes"
        }
        release mixtures
      end
    end

    if yeast_plates.length > 0
      # show {
      #   title "Place in 30 C incubator"
      #   check "Place all #{yeast_plates.length} plates with id #{(yeast_plates.collect {|x| x.id}).join(", ")} into 30 C incubator"
      # }
      yeast_plates.each do |y|
        y.location = "30 C incubator"
        y.save
      end
      release yeast_plates, interactive: true
    end

    release [peg] + [lioac] + [ssDNA], interactive: true
    release yeast_competent_cells + stripwells

    io_hash[:yeast_plate_ids]= yeast_plates.collect {|x| x.id} if yeast_plates.length > 0
    io_hash[:yeast_transformation_mixture_ids] = yeast_transformation_mixtures_markers["kan"].collect {|x| x.id} if yeast_transformation_mixtures_markers["kan"]
    return {io_hash: io_hash}

  end

end
