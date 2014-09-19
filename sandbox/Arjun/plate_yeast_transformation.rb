needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      yeast_transformation_mixture_ids: [],plasmid_ids:[]
    }
  end
  
  def main
    
    yeast_transformation_mixtures = input[:yeast_transformation_mixture_ids].collect{|tid| find(:item, id: tid )[0]}
    plasmids = input[:plasmid_ids].collect{|pid| find(:item, id: pid )[0]}
    selections = plasmids.sample.properties[:Yeast Marker]
    
    take yeast_transformation_mixtures, interactive: true
    
    counter=0
    plates = []
    yeast_transformation_plate_ids=[]
    yeast_transformation_mixtures.each do |transformation_mixture|
      
      j = produce new_sample transformation_mixture.sample.name, of: "Yeast Strain", as: "Yeast Plate"
      yeast_transformation_plate_ids.push([j[:id]])
      
      if selections[counter]=="URA"
        plate = choose_object "SDO -Ura Plate (sterile)"
        plates.push([plate])
        
        show{
          note "Label plate with your initials, the date, the initials #{input[:initials]} and the ID:
        
        
        
      elseif selections[counter]=="TRP"
      
      elseif selections[counter]=="LEU"
      
      elseif selections[counter]=="HIS"
      
      else
        #get statement for the selection plate
      end
      
      counter=counter+1
    end
    
  end
  
end
