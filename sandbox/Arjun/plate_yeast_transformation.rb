needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      yeast_transformation_mixture_ids: [27411],plasmid_ids:[27262],initials:["AK"]
    }
  end
  
  def main
    
    yeast_transformation_mixtures = input[:yeast_transformation_mixture_ids].collect{|tid| find(:item, id: tid )[0]}
    plasmids = input[:plasmid_ids].collect{|pid| find(:item, id: pid )[0]}
    
    
    take yeast_transformation_mixtures, interactive: true
    
    show{
      title "Resuspending in water"
      check "Spin down all the yeast transformation mixtures in samll table top centrifuge for ~1 minute"
      check "Pipette off supernatant being careful not to disturb yeast pellet"
    }
    
    show{
      title "Resuspending in water"
      check "Add 200ul of sterile water to each eppendorf tube"
      check "Resuspend the pellet by vortexing the tube throughly"
      warning "Make sure the pellet is resuspended and there are no cells stuck to the bottom of the tube"
    }
    
    counter=0
    plates = []
    yeast_transformation_plate_ids=[]
    yeast_transformation_mixtures.each do |transformation_mixture|
      
      j = produce new_sample transformation_mixture.sample.name, of: "Yeast Strain", as: "Yeast Plate"
      yeast_transformation_plate_ids.push([j[:id]])
      
      show{
        note "#{plasmids[counter].sample.properties[:key4]}"
      }
      
      
      if plasmids[counter].sample.properties["Yeast Marker"]=="URA"
        plate = choose_object "SDO -Ura Plate (sterile)"
        plates.push([plate])
        
      else if plasmids[counter].sample.properties["Yeast Marker"]=="TRP"
        plate = choose_object "SDO -Trp Plate (sterile)"
        plates.push([plate])
        
      else if plasmids[counter].sample.properties["Yeast Marker"]=="LEU"
        plate = choose_object "SDO -Leu Plate (sterile)"
        plates.push([plate])
        
      else if plasmids[counter].sample.properties["Yeast Marker"]=="HIS"
        plate = choose_object "SDO -His Plate (sterile)"
        plates.push([plate])
        
      else
        #get statement for the selection plate
      end
      
      show{
        check "Label plate with your initials, the date, the initials #{input[:initials]} and the ID: #{j[:id]}"
        check "Flip the plate and add 4-5 glass beads to it"
        check "Add 200ul of the transformation mixture from the tube labeled #{transformation_mixture[:id]}"
      }      
      
      counter=counter+1
    end
    
    show{
      check "Shake the plates in all directions to evely spread the culture over its surface till its dry"
    }
    
    show{
      check "Put the plates with the agar side up in the 30C incubator"
    }
    
  end
  
end
