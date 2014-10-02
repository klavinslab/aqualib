##This protocol starts overnight liquid cultures for bacteria from plates

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
	plate_ids: []
	n_colony: []
	}
end

def main
  plates=input[:plate_ids]
  n_cols=input[:n_colony]

	plate_number = plate_ids.length
	plates_full = find(:item, id: plate_ids)
  
  show{
    title "This protocol starts overnight bacterial culutres from agar plates."
  }
  
  take plates, interactive: true
  
  show{
    total_tubes=
  }
  
  
  
  
  
end

