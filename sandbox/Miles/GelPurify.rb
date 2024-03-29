#This protocol purifies gel slices into fragment stocks
#Still need to alter the protocol to take a hash as input and output a hash
#Also need to modify the protocol to be able to run indepently of a metacol

needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
	


include Standard
include Cloning


 def debug
    false
 end


def arguments
	{
	gelslice_ids: [27327, 27328]
	}
end

def main
	
	slices=input[:gelslice_ids]
	
	slice_number = slices.length
	

	slices_full = find(:item, id: slices )

	
	show{
		title "This protocol purfies gel slices into DNA fragment stocks."
	}
	
	take slices_full, interactive: true,  method: "boxes"
	
	
	
	
	show{
		s=*(1..slice_number)
		
		title "Lable the gel slice tubes with the following numbers."
		table [["Tube Number", "Gel Slice ID Number"]].concat(s.zip slices)
	}
	
	weights=[]
	data = show{
		title "Weigh the gel slices."
		check "Zero the scale"
		check "Weigh each slice and record it's weight on the side of the tube in grams."
		note "Enter the recorded weights 1 through #{slice_number} from top to bottom."
		slices_full.each{ |gs|
			get "number", var: "w#{gs.id}" 
		}
	}	
	
	w = slices_full.collect{ |gs| data["w#{gs.id}".to_sym]}
	
	
	qgs=[]
	count3=0
	while count3 < slice_number do
  		label=count3+1
  		qg=w[count3]*3000
  		qg.floor
  		qgs[count3]=qg
  		count3=count3+1
	end
	
	show{
		s=*(1..slice_number)
		title "Add the following volumes of QG buffer to the corresponding tube."
		table [["Tube", "QG Volume in µl"]].concat(s.zip qgs)
	}
	
	show{
		title "Place tubes in 50 degree heat block for about 10 minutes. Vortex every few minutes to speed up the process."
		note "10 minutues or until the gel slice is competely dissovled."
		note "Add 1x volume (1 uL to 1 mg of gel slice) isopropanol. Pipette up and down to mix"
	}
	
	show{
		  title "Check the boxes as you complete each step."
		  check "Add tube contents to LABELED pink Qiagen columns"
		  check "be sure to add a maximum of 750µl to each pick columns"
		  check "Spin at top speed (> 17,900 g) for 1 minute to bind DNA to columns"
		  check "after spin empty collection columns"
		  check "Add 750 uL PE buffer to columns and wait five minutes"
		  check "Spin at top speed (> 17,900 g) for 30 seconds to wash columns."
		  check "Empty collection tubes."
		  check "Add 500 uL PE buffer to columns and wait five minutes"
		  check "Spin at top speed (> 17,900 g) for 30 seconds to wash columns"
		  check "Empty collection tubes."
	}
	
	show{
		check"Spin at top speed (> 17,900 g) for 1 minute to remove all PE buffer from columns"
	}
	
	show{
		"Check the boxes as you complete each step."
		  check "Label 1.5 ml Eppendorf tubes. Transfer pink columns to empty Eppendorf tubes"
		  check "Add 30 uL molecular grade water or EB elution buffer to center of column."
		  note "Be very careful to not pipette on the wall of the tube"
		  check "Wait five minutes"
		  check "Elute DNA into Eppendorf tubes by spinning at top speed (> 17,900 xg) for one minute"
	}
	
	show{
		title "Measure Fragment DNA Concentration"
		note "Go to B9 and nanodrop all of tubes. Record Concentrations on the side of the tube."
		note "Enter all the DNA concetrations of tubes 1 through #{slice_number} below from top to bottom"
		slices_full.each{ |gs|
			get "number", var: "c#{gs.id}"
		}
	}	
	
	c = slices_full.collect{ |gs| data["c#{gs.id}".to_sym]}
	
	
	fragments=[]
	slices_full.each do |pid|
		j=produce new_sample pid.sample.name, of: "Fragment", as: "Fragment Stock"
		fragments.push(j)
	end
	
	show{
		y=fragments.map{|e| e.id}
		
		s=*(1..slice_number)
		title "Label the tubes with their aquairum IDs"
		table [["Tube", "Fragment Stock ID Number"]].concat(s.zip y)
		
		
		
	}
	
	count=0
	while count < slice_number do
		fragments[count].datum={concentration: c[count]}
		count=count+1
	end
	
	count1=0
	while count1 < slice_number do
		touch slices_full[count1]
		slices_full[count1].mark_as_deleted
		count1=count1+1
	end
	
	release(fragments, interactive: true)
	end

end

