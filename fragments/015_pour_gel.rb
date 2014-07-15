needs "aqualib/lib/standard"

class Protocol

  include Standard

  def debug
    false
  end

  def arguments
    {
       percentage: 0.8,
       comb_1: 2,
       comb_2: 2
    }
    #   percentage: number, "Enter the percentage gel to make (e.g. 1 = 1%)"
    #   comb_1: number, "Enter '1' for 6 thin lanes. Enter '2' for 6 thick lanes. Enter '3' for 10 thin lanes. Enter '4' for 10 thick lanes"
    #   comb_2: number, "Enter '0' for no second comb. Enter '1' for 6 thin lanes. Enter '2' for 6 thick lanes. Enter '3' for 10 thin lanes. Enter '4' for 10 thick lanes"
  end


  def main

    comb_1 = input[:comb_1]
    comb_2 = input[:comb_2]

    show {
      title "Pour a 50 mL agarose gel"
      note "Log out, go to the gel room , and log in there to run this protocol. It will be under 'Protocols > Pending Jobs'."
    }

    show {
      title "Work in the gel weigh area"
      note "Work in the gel weigh area (A5.300-A5.305) until otherwise indicated."
      warning "Wear gloves at all times!"
    }

    show {
      title "Wear eye protection"
      warning "Put on the clear protective glasses"
    }

    agarose = choose_object "Ultrapure* Agarose"

    gel_volume = 50.0
    agarose_mass = (input[:percentage] / 100.0) * gel_volume
    error = (agarose_mass * 0.05).round 5

    show {
      title "Add #{agarose_mass} g agarose to flask"
      bullet "Go to the station at A5.300. Obtain a flask from on top of the microwave M2."
      bullet "Using a digital scale, measure out #{agarose_mass} g (+/- #{error} g) of agarose powder and add it to the flask."
      bullet "Add agarose by tipping and shaking the bag, removing excess to the waste container by folding the weigh paper."
      image "gel_measure_agarose"
    }

    show {
      title "Wipe down the weigh area"
      note "Use a 70% ethanol spray bottle and kimwipes, "
    }

    show {
      title "Add 1X TAE"
      note "Get a graduated cylinder from on top of the microwave at A5.305. Measure and add 50 mL of 1X TAE from jug J2 at A5.500 to the flask."
      image "gel_measure_tae"
    }

    show {
      title "Microwave into solution"
      bullet "Swirl the flask to mix for about two seconds."
      bullet "Microwave 70 seconds on high in microwave M2, then swirl. The agarose should now be in solution."
      bullet "If it is not in solution, microwave 7 seconds on high, then swirl. Repeat until dissolved."
      warning "Use a paper towel to handle the flask."
      image "gel_in_solution"
    }

    show {
      title "Work in the gel pouring area"
      note "For the remainder of this protocol, work in the gel pouring area (A7.320-A7.325). Carefully transfer the flask containing molten agar to A7.320 using a paper towel."
    }

    gel_green = choose_object "GelGreen Nucleic Acid Stain"

    gel_green_volume = gel_volume / 10.0  # in µL

    show {
      title "Add #{gel_green_volume} µL GelGreen"
      note "Using a 10 µL pipetter, take up #{gel_green_volume} µL of GelGreen into the pipet tip. Expel the GelGreen directly into the molten agar (under the surface), then swirl to mix."
      warning "GelGreen is supposedly safe, but stains DNA and can transit cell membranes (limit your exposure)."
      warning "GelGreen is photolabile. Limit its exposure to light by putting it back in the box."
      image "gel_add_gelgreen"
    }

    release [ agarose, gel_green ], interactive: true

    gel_box = choose_object "49 mL Gel Box With Casting Tray (clean)"

    combs = [ "6-well", "6-well", "10-well", "10-well"   ]
    sides = [ "thinner", "thicker", "thinner", "thicker" ]

    show {
      title "Add top comb"
      check "Retrieve a #{combs[comb_1]} purple comb from A7.325"
      check "Position the gel box With the electrodes facing away from you. Add a purple comb to the side of the casting tray nearest the side of the gel box."
      check "Put the #{sides[comb_1]} side of the comb down"
      note "Make sure the comb is well-situated in the groove of the casting tray"
      image "gel_comb_placement"
    }

    unless comb_2 == 0
      show {
        title "Add bottom comb"
        check "Retrieve a #{combs[comb_2]} purple comb from A7.325"
        check "Position the gel box With the electrodes facing away from you. Add a purple comb to the center of the casting tray."
        check "Put the #{sides[comb_2]} side of the comb down"
        note "Make sure the comb is well-situated in the groove of the casting tray"
        image "gel_comb_placement"
      }
    end

    gel = produce new_object "50 mL 1 Percent Agarose Gel in Gel Box"
    release [ gel_box ]
    gel.move "A7.325"

    show {
      title "Pour and label the gel"
      note "Using a gel pouring autoclave glove, pour the gel from the flask into the casting tray. Pour slowly and in a corner for best results. Pop any bubbles with a 10 µL pipet tip."
      note "Write id #{gel} on piece of lab tape and affix it to the side of the gel box."
      note "Leave the gel to location A7.325 to solidify"
      image "gel_pouring"
    }

    release [ gel ]

    show {
      title "Clean up!"
      check "Place the graduated cylinder back on top of microwave M2."
      check "Place the flask back on top of microwave M2."
    }

  end

end


