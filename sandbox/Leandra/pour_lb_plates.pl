information "Pour LB plates from 200, 400, or 800 mL sources."


# TODO: Add the date to each plate (using stamp eventually)
argument
  n: number, "Enter the number of bottles you are pouring."
  volume: number, "Enter the volume of LB Agar you are pouring in mL. Valid options are 200, 400, or 800."
  antibiotic: string, "Enter the type of antibiotic you want. Valid options are Amp, Kan, Chlor, SDAc, or None."
  iptg: string, "Add IPTG? Enter Yes or No."
  atc: string, "Add aTc? Enter Yes or No."
  xgal: string, "Add X-gal? Enter Yes or No."
end


if volume != 200 && volume != 400 && volume != 800
  step
    description: "The LB Agar volume was incorrectly entered as %{volume}."
    getdata
      volume: number, "Enter the volume of LB Agar being poured.", [200, 400, 800]
    end
  end
end
if iptg != "Yes" && iptg != "No"
  step
    description: "The IPTG preference was incorrectly entered as %{iptg}."
    getdata
      iptg: string, "Add IPTG?", ["Yes", "No"]
    end
  end
end
if atc != "Yes" && iptg != "No"
  step
    description: "The aTc preference was incorrectly entered as %{atc}."
    getdata
      atc: string, "Add aTc?", ["Yes", "No"]
    end
  end
end
if xgal != "Yes" && iptg != "No"
  step
    description: "The X-gal preference was incorrectly entered as %{xgal}."
    getdata
      xgal: string, "Add X-gal?", ["Yes", "No"]
    end
  end
end
if antibiotic != "Amp" && antibiotic != "Kan" && antibiotic != "Chlor" && antibiotic != "SDAc" && antibiotic != "None"
  step
    description: "The antibiotic preference was incorrectly entered as %{antibiotic}."
    getdata
      antibiotic: string, "Enter the type of antibiotic you want to add. If none, select 'None'.", ["Amp", "Kan", "Chlor", "SDAc", "None"]
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


antibiotic_name = ""  # Initialize global variable
antibiotic_name2 = ""
antibiotic_volume = ""  # Initialize global variable
antibiotic_volume2 = ""
antibiotic_number = ""  # Initialize global variable
antibiotic_number2 = ""
product_name = ""  # Initialize global variable
if antibiotic == "Amp"
  antibiotic_name = "100X 1 mL Ampicillin Aliquot"
  antibiotic_volume = volume / 100.0
  antibiotic_number = antibiotic_volume * n
  product_name = "LB Amp Plate (sterile)"
elsif antibiotic == "Kan"
  antibiotic_name = "200X 1 mL Kanamycin Aliquot"
  antibiotic_volume = volume / 200.0
  antibiotic_number = antibiotic_volume * n
  product_name = "LB Kan Plate (sterile)"
elsif antibiotic == "Chlor"
  antibiotic_name = "1000X 1 mL Chloramphenicol aliquot"
  antibiotic_volume = volume / 1000.0
  antibiotic_number = 1
  # TODO: does 'ceil' functionality exist? Would be useful for calculations
  product_name = "LB Chlor Plate (sterile)"
elsif antibiotic == "SDAc"
  antibiotic_name = "200X 1 mL Kanamycin Aliquot"
  antibiotic_name2 = "100X 1 mL Ampicillin Aliquot"
  antibiotic_volume = volume / 200.0
  antibiotic_volume2 = volume / 500.0
  antibiotic_number = antibiotic_volume * n
  antibiotic_number2 = antibiotic_volume2 * n
  product_name = "LB Kan/(low)Amp Plate (sterile)"
elsif antibiotic == "None"
  product_name = "LB Plate (sterile)"
end


take
  bottles = n bottle_type
  plates = n_empty_plates "Petri Dish"
end


antibiotic_aliquots = ""  # Initialize global variable
if antibiotic != "None"
  take
    antibiotic_aliquots = antibiotic_number antibiotic_number2 antibiotic_name antibiotic_name2
  end

  step
    description: "Thaw the antibiotic aliquot(s)"
    note: "The aliquots should thaw at room temperature within 10 minutes. You can melt them faster by heating with your hand and vortexing."
 end

  step
    description: "Add %{antibiotic_volume} mL of %{antibiotic_name}"
    note: "Repeat this step for each bottle. If possible, keep bottles at in a 37°C heat bath or incubator when not on a hot plate. Otherwise, work quickly.\n\nBottle setup: keep the bottle on the hot plate at B1.335 while adding antibiotics. Keep the bottle capped whenever you aren't immediately pipetting in antibiotics.\n\nPipetting: for each aliquot, spin on benchtop minifuge before opening. Using a 1000 µL micropipette, add a total of %{antibiotic_volume} mL of antibiotic solution to the LB Agar bottle. You can add 1000 µL at a time. Ampicillin sticks to the side of the pipet tip, but you can ignore small amounts of residue.\n\nRecap the bottle when finished."
    warning: "Make sure the media is at about 50°C (compare to the 50°C heat block using your hand)"
  end
end

if iptg == "Yes"
  take
    iptg_aliquot = 1 "IPTG 1M stock solution"
  end

  iptg_volume = 120.0 * volume / 800

  step
    description: "Add %{iptg_volume} µL of IPTG"
    note: "Repeat this step for each bottle. If possible, keep bottles at in a 37°C heat bath or incubator when not on a hot plate. Otherwise, work quickly.\n\nBottle setup: keep the bottle on the hot plate at B1.335 while adding IPTG. Keep the bottle capped whenever you aren't immediately pipetting in antibiotics.\n\nPipetting: for each aliquot, spin on benchtop minifuge before opening. Using a 1000 µL micropipette, add a total of %{iptg_volume} µL of antibiotic solution to the LB Agar bottle. You can add 1000 µL at a time.\n\nRecap the bottle when finished."
    warning: "Make sure the media is at about 50°C (compare to the 50°C heat block using your hand)"
  end
end


# FIXME: remove these debug lines after items taken are accurate
#step
#  description: "Plates that should've been taken, then plates taken, then antibiotics"
#  note: "%{n_empty_plates}\n\n%{plates}\n\n%{antibiotic_aliquots}"
#end


if atc == "Yes"
  # FIXME: add this to inventory
  take
    # FIXME: bioturk gives a useless message if number is omitted - it actually points to atomic expression error at next 'step'
    atc = 1 "aTc 100 mg/mL stock solution"
  end

  # FIXME: Figure out this calculation (currently is the one for IPTG)
  atc_volume = 120.0 * volume / 800

  step
    description: "Add %{atc_volume} µL of aTc"
    note: "Repeat this step for each bottle. If possible, keep bottles at in a 37°C heat bath or incubator when not on a hot plate. Otherwise, work quickly.\n\nBottle setup: keep the bottle on the hot plate at B1.335 while adding aTc. Keep the bottle capped whenever you aren't immediately pipetting inducer.\n\nPipetting: for each aliquot, spin on benchtop minifuge before opening. Using a 1000 µL micropipette, add a total of %{atc_volume} µL of inducer to the LB Agar bottle. You can add 1000 µL at a time.\n\nRecap the bottle when finished."
    warning: "Make sure the media is at about 50°C (compare to the 50°C heat block using your hand)"
  end
end


if xgal == "Yes"
  take
    xgal_aliquot = 1 "xgal stock solution"
  end


  # FIXME: Figure out this calculation (currently is the one for IPTG)
  xgal_volume = 1600 * volume / 800

  step
    description: "Add %{xgal_volume} µL of X-gal"
    note: "Repeat this step for each bottle. If possible, keep bottles at in a 37°C heat bath or incubator when not on a hot plate. Otherwise, work quickly.\n\nBottle setup: keep the bottle on the hot plate at B1.335 while adding aTc. Keep the bottle capped whenever you aren't immediately pipetting in substrate.\n\nPipetting: for each aliquot, spin on benchtop minifuge before opening. Using a 1000 µL micropipette, add a total of %{xgal_volume} µL of substrate to the LB Agar bottle. You can add 1000 µL at a time.\n\nRecap the bottle when finished."
    warning: "Make sure the media is at about 50°C (compare to the 50°C heat block using your hand)"
  end
end


step
  description: "Lay out plates on workspace."
  note: "Lay out plates individually on your workspace, lid side up, in preparation for pouring."
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
  note: "Mark the side of each poured plate with a marker: purple for Amp, green for Kan, and blue for Chlor."
end


# IDEA: Split here and use metacol for the wait?
step
  description: "Let plates cool."
  note: "Let the plates cool until solid. You can verify that the plates are cool because the agar becomes opaque. If you keep them separate and unstacked, they will cool much faster and more evenly. This should take 10-20 minutes."
end


step
  description: "Stack and label."
  note: "Once the plates are cool, invert all of them lid down. Stack them (lid down) in groups of about 20. Label a piece of lab tape with LB, the antibiotic type if applicable, the inducer if applicable, X-gal if applicable. Apply the tape to the top plate on the stack."
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


if antibiotic == "None"
  produce
    n_poured product_name
    release poured_plates
    location: "A1.110"
  end
else
  produce
    n_poured product_name
    release poured_plates
    location: "A1.110"
  end
  release antibiotic_aliquots
end


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
