	class Protocol
	
	  def main
	  
	    ladders = find(:item, sample: { name: "1 kb Ladder" } )
	    
	    ladders.each do |ladder|
	    
	      data = show {
	        title "Item Number #{ladder.id}"
	        note "This item should be at location #{ladder.location}"
	        select ["Yes", "No"], var: "okay", label: "Is the item in the proper location?"
	      }
	      
	      if data[:okay] == "No"
	        show {
	          title "Yikes!"
	          warning "Do something to find item number #{ladder.id}!!!"
	        }
	      end
	    
	    end
	    
	  end
	  
	end