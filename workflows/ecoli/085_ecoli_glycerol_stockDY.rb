needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      overnights:SampleType.where("name='TB Overnight of Plasmid'")[0]
    }
  end
  
  def main
    
      overnights = find(:item, { sample: input[:overnights] } )
      
      take overnights
      
      number_overnights = overnights.length
      
      glycerol = choose_sample "50 percent Glycerol (sterile)"
      
      show 
      {
        title "Pipette 900 µL of 50 percent Glycerol stock into Cyro tube(s)."
        warning "Make sure not to touch the inner side of the Glycerol bottle with the pipetter."
      }
      
    
      (overnights).each do |overnight|
        
        show 
        {
          check "Pipette 900 µL of the E. coli plasmid overnight into a Cyro tube."
          check "Cap the Cryo tube and then vortex on a table top vortexer for about 20 seconds"
        }
        
        j = produce new_sample overnight, of: "TB Overnight of Plasmid", as: "Plasmid Glycerol Stock"
        
        release[j]
        
      end
      
      release [ overnights glycerol]
  end
  
end
