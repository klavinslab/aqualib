needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      yeast_transformation_mixture_ids: []
    }
  end
  
  def main
    
    yeast_transformation_mixtures = input[:yeast_transformation_mixture_ids].collect{|tid| find(:item, id: tid )[0]}
    
    take yeast_transformation_mixtures, interactive: true
    
    show{
      title "Incubate yeast transformations"
      check "Spin down the yeast transformation mixtures in samll table top centrifuge for ~1 minute"
      check "Pipette off supernatant being careful not to disturb yeast pellet"
    }
    
    show{
      title "Incubate yeast transformations"
      check "Add 1ml of YPAD to the eppendorf tube"
      check "Resuspend the pellet by vortexing the tube throughly"
      warning "Make sure the pellet is resuspended and there are no cells stuck to the bottom of the tube"
    }
    
    show{
      title "Incubate yeast transformations"
      check "Put tube in the styrofoam rack in the 30C shaker"
      check "Set a timer for 2.5 hours after which a plating protocol should be run"
    }
    
  end
  
end
