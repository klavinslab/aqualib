needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the plate ids as a list
      plate_ids: [3798,3797,3799],
      debug_mode: "Yes"
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?  
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    plates = io_hash[:plate_ids].collect { |x| find(:item, id: x)[0] }
    show {
      title "Work in the gel room"
      note "You will take images for plates using the gel room camera in this protocol."
      check "Go log into the gel room computer"
      warning "Be sure to wear gloves"
    }
    take plates, interactive: true
    show {
      title "Imaging guide"
      bullet "Place the agar part of the plate inverted on the transilluminator. Place the camera hood on the transilluminator. Turn on transilluminator by sliding you hand into the hood."
      bullet "Open EOS Utility software on the desktop, and click Camera Settings/Remote Shooting"
      bullet "In the pop up window EOS Rebel T3, make sure the settings are 2'', F4.5, ISO100, Tungsten(light bulb icon), S1."
      bullet "Click Live View shoot, view live plate picture in the Remote Live View Window, physically adjust the camera zoom lens to make sure plate takes up the image field of view."
      bullet "Try Test Shooting, if the test shooting image is not focused or the software shows Focus failure, go to the Remote Live View Window, in the focus section, adjust the focus by clicking the <<< << < > >> >>> buttons until the live image looks focused. Then go back to the EOS Rebel T3 window and click the the black round shutter botton."
    }

    show {
      title "Upload images"
      note "Take a picture for each plate, rename and upload following instructions below."
      plates.each do |p|
        check "Rename the image for plate #{p.id} as plate_#{p.id} and upload here:"
        upload var: "plate_#{p.id}"
        p.save
      end
    }

    colony_number = show {
      title "Estimate colony numbers"
      note "Estimate colony numbers for each plate and enter in the following."
      plates.each do |p|
        get "number", var: "c#{p.id}", label: "Estimate colony numbers for plate #{p.id}", default: 5
      end
    }

    location_plate = show {
      title "Parafilm plate"
      note "Parafilm each plate and store them in an available box in deli-fridge. Enter the number of the box in the following (DFP.0-DFP.7)"
      get "text", var: "x", label: "Enter the label of box you put in", default: "DFP.0"
    }

    # updates plates datum and location

    plates.each do |p|
      p.datum = { num_colony: colony_number[:"c#{p.id}".to_sym] }
      p.location = location_plate[:x]
      p.save
    end

    release plates, interactive: true

    # Set tasks in the io_hash to be plate imaged.
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.status = "imaged and stored in fridge"
        task.save
      end
    end
    return {io_hash: io_hash}
  end # main
end # Protocol


#   def main
#   	show {
#       	title "This protocol describes how to take a picture of a plate and count the number of colonies on the plate." 
      	
#       	note     "In this protocol you will use the gel station camera to take a picture
#      			 of the plate and use software (or human eye) to get the colony count of the plate."
#     	}
    	
#   	items = find(:item, id:input[:Transformed_E_coli_Strain_id])
#   	taken_plates = take items, interactive:true
  	
#     show {
#       	title  "Put the camera hood on transilluminator."
      	
#       	note  "Go the the Gel room, place the agar part of the plate inverted on the transilluminator.
#      		  Place the camera hood on the transilluminator. Turn on transilluminator by sliding you hand into the hood."
#     	}
     
#     show {
#       	title  "Set up the camera and remote shooting software on the computer"
      	  		
# 	  	check 	"Turn on the camera if it is off"
	  
# 		check 	"Open EOS Utility software on the desktop, and click Camera Settings/Remote Shooting"
	  	
# 	  	check 	"In the pop up window EOS Rebel T3, make sure the settings are 2'', F4.5, ISO100, Tungsten(light bulb icon), S1."
	    
#  		check 	"Click Live View shoot and in the pop up Remote Live View Window, click Test shooting"
	  		    	  	
# 	  	check 	"If the Test shooting image is not focused or the software shows Focus failure, go to the Remote Live View Window, in the focus
# 	    		section, adjust the focus by clicking the <<< << < > >> >>> buttons until the live image looks focused. Then go back to the EOS 
# 	    		Rebel T3 window and click the the black round shutter botton"
	    		
# 	    check 	" If the Test shooting image is focused, move on to the next step."
# 	    }
	    
# 	counts = []    		
#  	taken_plates.each do |plate|
#  		plate_id = plate.id
 		
#  		show {
#  			title "Take a picture of plate #{plate_id}."
 			
# 	  		note 	 "If this is the first image, go back to the EOS Rebel T3 window."
	  		
# 	  		note	 "Click the the black round shutter botton to take a picture."
#  			}

#       	show {
#       		title   "Rename the picture in Dropbox"
      	
#       		note  	"Open Dropbox/GelImages, under today's date folder and find the picture you just took.
# 	     		Rename the picture as the plate_#{plate_id}."
#     		}
    
#      	 show {
#       		title   "Drag the picture of plate #{plate_id} into OpenCFU software and get the count."
      	
#       		note  	 "Open the OpenCFU software, drag the picture into the software and wait for the software to count the colonies."
#     		}
    	
#      	 data = show {
#       		title    "Record the colony count."
      	
#       		note  	 "If the software recognizes the colonies correctly and give a reasonable count, record
# 	     			that number below. If not, count the number of colonies by dividing up the plate in
# 	     			four regions, get the count in each region and sum up as the final count." 
	     	
# 	     	get 	"number", var: "count", label: "Record the colony count here"
#     		}
    	
#     	counts.append(data[:count])
#   	end
  	   	
	
#     show {
#       	title     "Store the plate(s) in 4C fridge."
      	
#       	note  	 "Turn off the transillumniator and camera, remove the camera hood, take the plate from transilluminator, wrap up
#      			the plate with parafilm and put it the in the Box 0 in deli fridge located at D2.100."
#     	}	
    	
#    	locations = []
# 	taken_plates.each do |plate|
# 		plate_id = plate.id
# 		moredata=show {
# 		get 	"text", var: "location", location: "Record the location of plate #{plate_id} here", default: "D2.100"
#     	}
# 	locations.append(moredata[:location]) 	
#     end
    
#     release taken_plates
 	
#  	return counts 
#   end
  
# end



