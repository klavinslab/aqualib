#This protocol purifies gel slices into fragment stocks

needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
	


include Standard
include Cloning


def arguments
	{
	gelslice_ids: SampleType.where("name='Gel Slice'")[0] 

def main
	
	slices = find(:item, {sample: input[:gelslice_ids]})
	
	slice_number = slices.length
	
	show{
		title "This protocol purfies gel slices int DNA fragment stocks."
	}
	
	take slices, interactive: true,  method: "boxes"
	
	show{
		title "Lable the gel slice tubes with the following numbers."
		table [["Tube", "Number"],[[slices], [1:slice_number]]]
	}
	
	data = show{
		title: "Weigh the gel slices."
		check: "Zero the scale"
		check: "Weigh each slice and record it's weight on the side of the tube in grams."
		note: "Enter the recorded weights below."
		slices.each{
			get "number", var: "w#{slices.id}"
		}
	}	
	
	w = slices.collect{ |slice_number| data["w#{slices.id}".to_sym]}
	
end
