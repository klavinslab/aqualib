#This protocol purifies gel slices into fragment stocks

needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
	


include Standard
include Cloning


 def debug
    true
 end


def arguments
	{
	gelslice_ids: [27327, 27238]
	}
end

def main
	
	slices=input[:gelslice_ids]
	
	slice_number = slices.length
	

	slices_full = find(:item, id: slices )

	
	show{
		title "This protocol purfies gel slices int DNA fragment stocks."
	}
	
	take slices_full, interactive: true,  method: "boxes"
	
	
	
	
	show{
		s=*(1..slice_number)
		
		title "Lable the gel slice tubes with the following numbers."
		table [["Tube", "Number"],[slices, s]]
		note s
		note slices
	}
	
	data = show{
		title "Weigh the gel slices."
		check "Zero the scale"
		check "Weigh each slice and record it's weight on the side of the tube in grams."
		note "Enter the recorded weights below."
		slices_full.each{
			get "number", var: "w"
		}
	}	
	
	weights = slices.collect{ |slice_number| data[w.to_sym]}
	
end

end
