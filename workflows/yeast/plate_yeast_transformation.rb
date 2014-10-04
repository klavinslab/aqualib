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
      yeast_transformation_mixture_ids: [12293,12294,12295,12296,12297,12298],
      plasmid_ids: [27507,27508,27509],
      initials:["YY"]
    }
  end
  
  def main
    
    yeast_transformation_mixtures = input[:yeast_transformation_mixture_ids].collect {|tid| find(:item, id: tid )[0]}
    plasmids = input[:plasmid_ids].collect {|pid| find(:item, id: pid )[0]}
    
    
    take yeast_transformation_mixtures, interactive: true
    
    show{
      title "Resuspend in water"
      check "Spin down all the tubes in a samll table top centrifuge for ~1 minute"
      check "Pipette off supernatant being careful not to disturb yeast pellet"
      check "Add 600 µL of sterile water to each eppendorf tube"
      check "Resuspend the pellet by vortexing the tube throughly"
      warning "Make sure the pellet is resuspended and there are no cells stuck to the bottom of the tube"
    }

    yeast_plates = yeast_transformation_mixtures.collect {|y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}
    initials = input[:initials]

    yeast_plates.each do |y|
      y.location = "30 C incubator"
      y.save
    end

    yeast_transformation_mixtures.each do |y|
      y.location = "DFP"
      y.save
    end

    show{
      check "Label plates with the following ids"
      note (yeast_plates.collect{|y| "#{y.id}"})
      check "Flip the plate and add 4-5 glass beads to it"
      check "Add 200 µL of the transformation mixture from the tube."
    }      

    show{
      check "Shake the plates in all directions to evely spread the culture over its surface till its dry"
      check "Put the plates with the agar side up in the 30C incubator"
    }   
    
    release yeast_plates, interactive: true

    release yeast_transformation_mixtures, interactive: true
    #need to release plates and transformation mixtures.
    
  end
  
end
