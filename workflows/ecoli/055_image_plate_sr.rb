class Protocol
  def arguments
    {
    	Transformed_E_coli_Strain_id: []
    }
  end

  def main
  	show {
      	title "This protocol describes how to take a picuture of a plate and count number of colonies on the plate." 
      	
      	note     "In this protocol you will use the gel station camera to take a picture
     			 of the plate and use software or human eye to get colony count on the plate."
    	}
    	
  	items = find(:item, id:input[:Transformed_E_coli_Strain_id])
  	taken_plates = take items, interactive:true
  	
    show {
      	title  "Put the camera hood on transilluminator"
      	
      	note  "Go the the Gel room, place the agar part of the plate inverted on the transilluminator.
     		  Place the camera hood on the transilluminator. Turn on transilluminator by sliding you hand into the hood."
    	}
     
    show {
      	title  "Take a picture using the camera and remote shooting software on the computer"
      	  		"Go the the Gel room, place the agar part of the plate inverted on the transilluminator.
     		  	Place the camera hood on the transilluminator. Turn on transilluminator by sliding you hand into the hood."
	  	
	  	check 	"Turn on the camera if it is off"
	  
		check 	"Open EOS Utility software on the desktop, and click Camera Settings/Remote Shooting"
	  	
	  	check 	"In the pop up window EOS Rebel T3, make sure the settings are 2'', F4.5, ISO100, Tungsten(light bulb icon), S1."
	  	
	  	check 	"click Live View shoot and in the pop up Remote Live View Window, click Test shooting"
	  	
	  	check 	 "If the Test shooting image looks focused, go back to the EOS Rebel T3 window and click the the black round shutter botton"
	  	
	  	check 	"If the Test shooting image is not focused or the software shows Focus failure, go to the Remote Live View Window, in the focus
	    		section, adjust the focus by clicking the <<< << < > >> >>> buttons until the live image looks focused. Then go back to the EOS 
	    		Rebel T3 window and click the the black round shutter botton"
	    }
	    		
 	taken_plates.each do |plate|
 		plate_id = plate.id
 		
 		show {
 			title "Do this for plate #{plate_id}"
 		}

      	show {
      		title   "Rename the picture in Dropbox"
      	
      		note  	"Open Dropbox/GelImages, under today's date folder and find the picture you just took.
	     		Rename the picture as the plate_id, where id should be replaced with the item number shown on your plate.
	     		For example, a plate with id 798 should have picture name plate_798."
    	}
    
     	 show {
      		title   "Drag the picture into OpenCFU software and get the count."
      	
      		note  	 "Open the OpenCFU software, drag the picture into the software and wait for the software to count the colonies."
    	}
    	
     	 show {
      		title    "Record the count."
      	
      		note  	 "If the software recognizes the coloines correctly and give a reasonable count, record
	     			that number below. If not, count the number of colonies by dividing up the plate in
	     			four regions, get the count in each region and sum up as the final count." 
    	}
  	end
  	   	
	counts = []
	taken_plates.each do |plate|
		show {
			get "number", var: "count", label: "Record the colony count here"
		}
		counts.append(count)
	end
	
    show {
      	title     "Store the plate(s) in 4C fridge."
      	
      	note  	 "Turn off the transillumniator and camera, remove the camera hood, take the plate from transilluminator, wrap up
     			the plate with parafilm and put it the in the Box 0 in deli fridge located at D2.100."
    	}	
    	
   	locations = []
	taken_plates.each do |plate|
		get "string", var: "location", location: "Record the location here", default: "D2.100"
		locations.append(location) 	
    end
 	

  end
end
