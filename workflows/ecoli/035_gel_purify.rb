#First version by Miles Gander, refactored by Yaoyu Yang.

needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
	
include Standard
include Cloning

def arguments
	{
		io_hash: {},
		gel_slice_ids: [28515,28516,28517,28510,28511,28512,28513,28514,28515,28507,28508],
		debug_mode: "Yes"
	}
end

def main
	io_hash = input[:io_hash]
	io_hash = input if input[:io_hash].empty?
	gel_slice_ids = io_hash[:gel_slice_ids]

	if io_hash[:debug_mode] == "Yes"
      def debug
        true
      end
    end

	gel_slices = find(:item, id: gel_slice_ids)
	gel_slice_lengths = gel_slices.collect {|gs| gs.sample.properties["Length"]}

	num = gel_slices.length
	num_arr = *(1..num)

	show {
		title "This protocol purfies gel slices into DNA fragment stocks."
		note "The following gel slices are going to be purfied"
		note "#{gel_slices.collect {|s| s.id}}"
	}
	
	take gel_slices, interactive: true,  method: "boxes"

	weights = show{
		title "Weigh each gel slice."
		check "Zero the scale"
		check "Weigh each slice and enter the recorded weights in the following:"
		gel_slices.each do |gs|
		  get "number", var: "w#{gs.id}", label: "Enter a number for tube #{gs.id}", default: 0.123
		end
	}

	gel_weights = gel_slices.collect { |gs| weights[:"w#{gs.id}".to_sym] }

	qg_volumes = gel_weights.collect { |g| (g*3000).floor}

	iso_volumes = gel_weights.collect { |g| (g*1000).floor}

	gel_slices.each_with_index do |gs,idx|
		if gs.sample.properties["Length"] >500 and gs.sample.properties["Length"] < 4000
			iso_volumes[idx] = 0
		end
	end

	
	show{
		# s=*(1..slice_number)
		title "Add the following volumes of QG buffer to the corresponding tube."
		table [["Gel Slices", "QG Volume in µl"]].concat(gel_slices.collect {|s| s.id}.zip qg_volumes)
	}
	
	show{
		title "Place all tubes in 50 degree heat block"
		timer initial: { hours: 0, minutes: 10, seconds: 0}
		note "Vortex every few minutes to speed up the process."
		note "Retreve after 10 minutues or until the gel slice is competely dissovled."
		note "Add isopropanol according to the following table. Pipette up and down to mix"
		table [["Gel slice", "Isopropanol"]].concat(gel_slices.collect {|s| s.id}.zip iso_volumes)
	}
	
	show {
		  title "Check the boxes as you complete each step."
		  check "Grab #{num} of pink Qiagen columns, label with 1 to #{num} on the top."
		  check "Add tube contents to LABELED pink Qiagen columns using the following table."
		  check "Be sure not to add more than 750 µL to each pick columns"
		  table [["Gel slices tube", "Qiagen column"]].concat(gel_slices.collect {|s| s.id}.zip num_arr)
		}
		  
    show {
    	title "Centrifuge"
		check "Spin at top speed (> 17,900 g) for 1 minute to bind DNA to columns"
		check "Empty collection columns by pouring waste liquid into waste liquid container."
		check "Add 750 µL PE buffer to columns and wait five minutes"
		check "Spin at top speed (> 17,900 g) for 30 seconds to wash columns."
		check "Empty collection tubes."
		check "Add 500 µL PE buffer to columns and wait five minutes"
		check "Spin at top speed (> 17,900 g) for 30 seconds to wash columns"
		check "Empty collection tubes."
		check "Spin at top speed (> 17,900 g) for 1 minute to remove all PE buffer from columns"
	}

	fragment_stocks = gel_slices.collect {|gs| produce new_sample gs.sample.name, of: "Fragment", as: "Fragment Stock"}

	show{
		  title "Transfer to 1.5 mL tube"
		  check "Label #{num} 1.5 mL tube with #{fragment_stocks.collect {|fs| fs.id}}"
		  check "Transfer pink columns to empty Eppendorf tubes using the following table."
		  table [["Qiagen column","1.5 mL tube"]].concat(num_arr.zip fragment_stocks.collect {|fs| fs.id})
		  check "Add 30 µl molecular grade water or EB elution buffer to center of column."
		  note "Be very careful to not pipette on the wall of the tube"
		  check "Wait one minute"
		  timer initial: { hours: 0, minutes: 1, seconds: 0}
		  check "Elute DNA into Eppendorf tubes by spinning at top speed (> 17,900 xg) for one minute"
	}
	
	concs = show{
		title "Measure DNA Concentration"
		note "Go to B9 and nanodrop all of 1.5 mL tubes, enter DNA concentrations for all tubes in the following:"
		fragment_stocks.each do |fs|
		  get "number", var: "c#{fs.id}", label: "Enter a number for tube #{fs.id}", default: 30.2
		end
	}

	# show {
	# fragment_stocks.each do |fs|
	# 	fs.datum = {}
	# 	note "#{concs[:"c#{fs.id}".to_sym]}"
	# 	fs.save
	# end
	# }

	#

	fragment_stocks.each do |fs|
		fs.datum = {concentration: concs[:"c#{fs.id}".to_sym], volume: 28}
		fs.save
	end

	# gel_slices.each do |gs|
	# 	gs.mark_as_deleted
	# end

	release fragment_stocks, interactive: true, method: "boxes"
	io_hash[:fragment_stock_ids] = fragment_stocks.collect{|fs| fs.id}
	return {io_hash: io_hash}

	end

end


