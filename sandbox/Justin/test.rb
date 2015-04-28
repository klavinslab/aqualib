needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol
  
  include Standard
  include Cloning
  
  def arguments
    {
    #Enter the plasmid stocks ids that you wish to convert to another plasmid 
    plasmidstock_ids: [17032,17034,17039],
    
    #Enter the corresponding plasmid you would like to convert the plasmid stock too
    plasmid_ids: [3546, 3547, 3539]
    }
  end
  
  def main
    show{
      	title "This is some title"
      	note "This is some note"
      }
    
    show{
      title "This is the next step"
    }
  end
  
end
