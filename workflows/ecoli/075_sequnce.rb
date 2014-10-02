needs "protocols/mutagenesis_workflow/lib/standard"
needs "protocols/mutagenesis_workflow/lib/cloning"

class Protocol
  
  include Standard
  include Cloning
  
  def debug
    false
  end

  def arguments
    {
    # Enter your first and last name initials
    initials: "YY",
    plasmid_item_ids: [11546, 11546, 11547, 11547],
    primer_ids: [9963, 9966, 9963, 9966],
    genewiz_tracking_number: "10-275726027"
    }
  end
 
  def main
  	initials = input[:initials]
    tracking_number = input[:genewiz_tracking_number]
    plasmid_items = input[:plasmid_item_ids].collect{|pid| find(:item, id: pid )[0]} 
    primer_items = input[:primer_ids].collect{|pid| find(:item, id: pid )[0]} 
    take plasmid_items + primer_items, interactive: true, method: "boxes"

    plasmid_lengths = plasmid_items.collect{|pls| pls.sample.properties["Length"]}
    plasmid_concs = plasmid_items.collect{|pls| pls.datum[:concentration]}
    plasmid_volume_list = []
    plasmid_lengths.each_with_index do |length, idx|
    	if length < 6000
    		plasmid_volume_list.push (500.0/plasmid_concs[idx]).round(1)
    	elsif length < 10000
    		plasmid_volume_list.push (800.0/plasmid_concs[idx]).round(1)
    	else
    		plasmid_volume_list.push (10000.0/plasmid_concs[idx]).round(1)
    	end
    end
    water_volume_list = plasmid_volume_list.collect{|v| (12.5-v).to_s + " µL"}
    plasmids_with_volume = input[:plasmid_item_ids].map.with_index{|pid,i| plasmid_volume_list[i].to_s + " µL of " + pid.to_s}
    primers_with_volume = input[:primer_ids].collect{|prid| "2.5 µL of " + prid.to_s }
    			
    # show {
    # 	note (water_volume_list.collect {|p| "#{p}"})
    # 	note (plasmid_volume_list.collect {|p| "#{p}"})
    # }

    stripwells = produce spread plasmid_items, "Stripwell", 1, 12
    show {
      title "Prepare Stripwells for sequencing reaction"
      stripwells.each_with_index do |sw,idx|
      	if idx < stripwells.length-1 and idx != stripwells.length-1
	        check "Grab a stripwell with 12 wells, label the first well with #{initials}#{idx*12+1} and last well with #{initials}#{idx*12+12}"
	        separator
	    else
	    	check" Grab a stripwell with #{plasmid_items.length.modulo(12)} wells, label the first well with #{initials}0#{idx*12+1} and last well with #{initials}0#{plasmid_items.length}"
        end
    end
    }

    load_samples_variable_vol_seq( ["Molecular Grade Water", "Plasmid", "Primer"], [
        water_volume_list,
        plasmids_with_volume,
        primers_with_volume
      ], stripwells ) 
    show {
      title "Put all stripwells in the Genewiz mailbox"
      note "Cap all of the stripwells"
      note "Put the stripwells into a zip-lock bag along with the Genewiz order form with tracking number #{tracking_number}"
      note "Ensure that the bag is sealed, and put it into the Genewiz mailbox"
    }
  end
end
