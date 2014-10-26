needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the gibson result ids as a list
      transformed_aliquots_ids: [11815,11816,11817,12282,3648],
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
    all_transformed_aliquots = io_hash[:transformed_aliquots_ids].collect { |tid| find(:item, id: tid)[0] }
    # if all_transformed_aliquots.length == 0
    #   show {
    #     title "No plating required"
    #     note "No transformed aliquots need to be plated."
    #   }
    #   return {io_hash: io_hash}
    # end
    take all_transformed_aliquots, interactive: true if all_transformed_aliquots.length > 0

    transformed_aliquot_marker_hash = Hash.new { |h,k| h[k] = [] }
    all_transformed_aliquots.each do |t|
    	transformed_aliquot_marker_hash[t.sample.properties["Bacterial Marker"].downcase[0,3]].push t
    end

    # show {
    # 	note "#{transformed_aliquot_marker_hash}"
    # }

    all_plates = []
    transformed_aliquot_marker_hash.each do |marker, transformed_aliquots|
    	unless marker == ""
	    	marker = "chlor" if marker == "chl"
	    	plates = transformed_aliquots.collect {|t| produce new_sample t.sample.name, of: "Plasmid", as: "E coli Plate of Plasmid"}
	    	all_plates.concat plates
	    	num = transformed_aliquots.length
	    	show {
	    		title "Grab #{num} #{"plate".pluralize(num)}"
	    		check "Grab #{num} LB #{marker[0].upcase}#{marker[1..marker.length]} Plate (sterile)"
	    		check "Label with the following ids #{plates.collect { |p| p.id }}"
	    	}
	    	show {
	    		title "Plating"
	    		check "Use sterile beads to plate 200 µL from transformed aliquots (1.5 mL tubes) on to the plates following the table below."
	    		check "Discard used transformed aliquots after plating."
	    		table [["1.5 mL tube", "LB+#{marker[0].upcase}#{marker[1,2]} plate"]].concat((transformed_aliquots.collect { |t| t.id }).zip plates.collect{ |p| { content: p.id, check: true } })
	    	}
	    else
	    	show {
	    		title "No marker info found"
	    		note "Place the following tubes into DFP and inform the plasmid owner that they need their Bacterial Marker info entered in the plasmid sample page."
	    		note "#{transformed_aliquots.collect { |t| t.id }}"
	    	}
	    end
    end

  	all_plates.each do |p|
  		p.location = "37 C incubator"
  		p.save
  	end

  	release all_plates, interactive: true if all_plates.length > 0
  	io_hash[:plate_ids] = [] if !io_hash[:plate_ids]
  	io_hash[:plate_ids].concat all_plates.collect { |p| p.id }

    # Set tasks in the io_hash to be on plate
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        task.status = "on plate"
        task.save
      end
    end
  	return {io_hash: io_hash}
  end # main

end # Protocol
