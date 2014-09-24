information "Pour SDAc plates from 200, 400, or 800 mL sources."


# TODO: Add the date to each plate (using stamp eventually)
argument
  n: number, "Enter the number of bottles you are pouring."
  volume: number, "Enter the volume of LB Agar you are pouring in mL. Valid options are 200, 400, or 800."
end


if volume != 200 && volume != 400 && volume != 800
  step
    description: "The LB Agar volume was incorrectly entered as %{volume}."
    getdata
      volume: number, "Enter the volume of LB Agar being poured.", [200, 400, 800]
    end
  end
end


bottle_type = ""  # Initialize global variable
n_empty_plates = ""  # Initialize global variable
if volume == 200
  bottle_type = "200 mL LB Agar (sterile)"
  n_empty_plates = 10 * n
elsif volume == 400
  bottle_type = "400 mL LB Agar (sterile)"
  n_empty_plates = 20 * n
else
  bottle_type = "800 mL LB Agar (sterile)"
  n_empty_plates = 40 * n
end


antibiotic_amp = "100X 1 mL Ampicillin Aliquot" # Initialize global variable
antibiotic_kan = "200X 1 mL Kanamycin Aliquot"
amp_volume = volume / 500.0  # Initialize global variable
kan_volume = volume / 200.0

amp_number = ""
if volume == 200
 amp_number = n
elsif volume == 400
 amp_number = n
else
 amp_number = 2 * n
end

kan_number = kan_volume * n  # Initialize global variable
product_name = "SDAc Plate (Kan + low Amp) (sterile)"  # Initialize global variable


take
  bottles = n bottle_type
  plates = n_empty_plates "Petri Dish"
end


#antibiotic_number = [ amp_number, kan_number ]
#antibiotic_name = [ antibiotic_amp, antibiotic_kan ] # Initialize global variable
#antibiotic_aliquots = ""

take
 amp = amp_number antibiotic_amp
 kan = kan_number antibiotic_kan
end

step
    description: "Thaw the antibiotic aliquot(s)"
    note: "The aliquots should thaw at room temperature within 10 minutes. You can melt them faster by heating with your hand and vortexing."
end

step
    description: "Add %{amp_volume} mL of %{antibiotic_amp} and %{kan_volume} mL of %{antibiotic_kan}"
    note: "Repeat this step for each bottle. If possible, keep bottles warm in a 37°C heat bath or incubator when not on a hot plate. Otherwise, work quickly.\n\nBottle setup: keep the bottle on the hot plate at B1.335 while adding antibiotics. Keep the bottle capped whenever you aren't immediately pipetting in antibiotics.\n\nPipetting: for each aliquot, spin on benchtop minifuge before opening. Using a 1000 µL micropipette, add a total of %{amp_volume} mL of Ampicillin and %{kan_volume} mL of Kanamycin to the LB Agar bottle. You can add 1000 µL at a time. Ampicillin sticks to the side of the pipet tip, but you can ignore small amounts of residue.\n\nRecap the bottle when finished."
    warning: "Make sure the media is at about 50°C (compare to the 50°C heat block using your hand)"
end


step
  description: "Pour 25 mL of media into each plate."
  note: "Repeat this step for each bottle.\n\nUncap the molten agar media bottle. Pour agar slowly into a plate (pour into the same location on the plate for the entire pour). It should take approximately 3 seconds for agar to cover the bottom of the plate. Continue pouring at the same rate for 1 more second and you will have poured approximately 25 mL. Replace the petri dish lid.\n\nIf bubbles form in the bottle while pouring, squirt a very small amount of ethanol into the bottle to break them up."
  getdata
    n_poured: number, "Enter the number of plates you actually poured."
  end
end


step
  description: "Mark the side of each plate"
  note: "Mark the side of each poured plate with a marker: purple for Amp and green for Kan."
end


# IDEA: Split here and use metacol for the wait?
step
  description: "Let plates cool."
  note: "Let the plates cool until solid. You can verify that the plates are cool because the agar becomes opaque. If you keep them separate and unstacked, they will cool much faster and more evenly. This should take 10-20 minutes."
end


step
  description: "Stack and label."
  note: "Once the plates are cool, invert all of them lid down. Stack them (lid down) in groups of about 20. Label a piece of lab tape with SDAc, LB Kan + low Amp, and the date. Apply the tape to the top plate on the stack."
end


step
  description: "Place in the 30 degree yeast incubator."
  note: "Place the poured plates in the 30 degree yeast incubator at A1.110 to dry overnight."
end


# Make an array accounting for the plates that are now empty so they can be released at the end and put back in the inventory
# Do the same for plates poured so they can be released when producing the new plates
ii = 0
poured_plates = []
empty_plates = []
while ii < n_empty_plates
  if ii < n_poured
    # FIXME: replaced with commented lines after fix to multiple takes
    poured_plates = append(poured_plates, plates[0])
    #poured_plates = append(poured_plates, plates[ii])
  else
    empty_plates = append(empty_plates, plates[0])
    #empty_plates = append(empty_plates, plates[ii])
  end
  ii = ii + 1
end



produce
    n_poured product_name
    release poured_plates
    location: "A1.110"
end
  
release [ amp_number, antibiotic_amp ]
release [ kan_number, antibiotic_kan ]



if n_poured < 40
  release empty_plates
end


empty_bottle_type = ""  # Initialize global variable
if volume == 800
  empty_bottle_type = "1 L Bottle (dirty)"
elsif volume == 400
  empty_bottle_type = "500 mL Bottle (dirty)"
elsif volume == 200
  empty_bottle_type = "250 mL Bottle (dirty)"
end


produce
  n empty_bottle_type
  location: "A8.310"
  note: "Rinse out in the sink at A8.310 first"
end
