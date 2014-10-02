needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      overnights: [27662, 27663, 27664, 27665]
    }
  end
  
  def main
    
      #parse overnights
      overnights= input[:overnights]
      overnight_ids = []
      overnights.each do |oid|
        overnight_ids.push find(:item, id: oid)[0].sample
      end
      overnight_uniq = overnight_ids.uniq
      
      take overnight_uniq
      
      
      
      number_overnights = overnights.length
      
      
      
      
   #   glycerol = choose_sample "50 percent Glycerol (sterile)"
      
      show {
          title "Pipette 900 µL of 50 percent Glycerol stock into Cyro tube(s)."
          warning "Make sure not to touch the inner side of the Glycerol bottle with the pipetter."
        }
      
    
      (overnights).each do |overnight|
        
        show {
            check "Pipette 900 µL of the E. coli plasmid overnight into a Cyro tube."
            check "Cap the Cryo tube and then vortex on a table top vortexer for about 20 seconds"
          }
        
        j = produce new_sample overnight, of: "TB Overnight of Plasmid", as: "Plasmid Glycerol Stock"
        
        release [j]
        
      end
      
      release [overnights, glycerol]
  end
  
end
