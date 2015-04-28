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
		title "Place all empty flasks at the clean station"
		}
    end
    show{
		title "Prepare equipment during spin"
		check "During the spin, take out #{num} QIAfilter Cartridge(s). Label them with #{overnight_ids}. Screw the cap onto the outlet nozzle of the QIAfilter Cartridge(s). Place the QIAfilter Cartridge(s) into a convenient tube or test tube rack."
		check "Label #{num} HiSpeed Tip(s). Place the HiSpeed Tip(s) onto a tip holder, resting on a 250 ml beaker. Add 10ml of QBT buffer to the HiSpeed Tip(s), allowing it to enter the resin."
   		 }
	end
  end
  
end
