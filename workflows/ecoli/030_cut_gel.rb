needs "aqualib/lib/standard"
class Protocol

  include Standard

  def debug
    false
  end

  def arguments
    {
      io_hash: {},
      gel_ids: [28130]
    }
  end

  def gel_band_verify col, options = {}
    m = col.matrix
    routes = []
    opts = { except: [] }.merge options

    (0..m.length-1).each do |i|
    	(0..m[i].length-1).each do |j|
    	  if m[i][j] > 0 && ! ( opts[:except].include? [i,j] )
    	    s = find(:sample,{id: m[i][j]})[0]
    	    length = s.properties["Length"]
    	    routes.push lane: [i,j], length: length
    	  end
    	end
	end

	show {
		title "Verify that each lane matches expected size"
		table [[ "Row", "Column", "Expected fragment size" ]].concat( routes.collect { |r| [ r[:lane][0]+1, r[:lane][1]+1, r[:length]] } )
		}

	return routes
  end

  def main
    io_hash = input[:io_hash]
  	gels = io_hash[:gel_ids].collect { |i| collection_from i }
  	take gels, interactive: true
  	slices = []
  	gels.each do |gel|
  		show {
  			title "Put the gel #{gel.id} on the transilluminator"
  			check "Clean the transilluminator with ethanol."
  			check "Put the gel #{gel.id} on the transilluminator."
  			check "Put the camera hood on, turn on the transilluminator and take a picture using the camera control interface on computer."
  			note "Rename the picture you just took as gel_#{gel.id}. Upload it!"
  			upload var: "my_gel_pic"
  		}
  		band_mockup = gel_band_verify( gel, except: [ [0,0], [1,0] ] )
  		gel_data = show {
  			title "How's the gel size?"
  			select ["Yes", "No"], var: "okay", label: "Does this gel looks as expected?"
  		}
  		if gel_data[:okay] == "Yes"
			s = distribute( gel, "Gel Slice", except: [ [0,0], [1,0] ], interactive: true ) {
				title "Cut gel slices and place them in new 1.5 mL tubes"
				note "Label the tubes with the id shown above"
				warning "Wear blue light goggles during this process"
			}
			produce s
			slices = slices.concat s
		end
  	end

  	show {
  		title "Clean up!"
  		note "Turn off the transilluminator"
  		note "Dispose of the gel and any gel parts by placing it in the waste container. Spray the surface of the transilluminator with ethanol and wipe until dry using kimwipes or paper towel."
  		note "Remove the blue light goggles and put them back where you found them."
  		note "Clean up the gel box and casting tray by rinsing with water. Return them to the gel station."
  	}

  	release slices, interactive: true, method: "boxes"
    io_hash[:gel_slice_ids] = slices.collect {|s| s.id}
    return io_hash

  end

end



