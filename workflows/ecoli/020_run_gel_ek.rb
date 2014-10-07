needs "aqualib/lib/standard"

class Protocol

  include Standard

  def debug
    false
  end

  def arguments
    {
      stripwell_ids: [],
      gels_ids: [],
      volume: 20       # The volume of PCR fragment to load in µL
    }
  end

  def main

    stripwells = input[:stripwell_ids].collect { |i| collection_from i }
    gels = input[:gel_ids].collect { |i| collection_from i }
    volume = input[:volume] || 20

    take stripwells + gels

    ladder = choose_sample "1 kb Ladder" 
    dye = choose_object "Gel Loading Dye Blue (6X)"

    show {
      title "Set up the power supply"
      note  "In the gel room, obtain a power supply and set it to 100 V and with a 40 minute timer."
      note  "Attach the electrodes of an appropriate gel box lid from A7.525 to the power supply."
      image "gel_power_settings"
    }

    show {
      title "Set up the gel box(s)."
      check "Remove the casting tray(s) (with gel(s)) and place it(them) on the bench."
      check "Using the graduated cylinder at A5.305, fill the gel box(s) with 200 mL of 1X TAE from J2 at A5.500. TAE should just cover the center of the gel box(s)."
      check "With the gel box(s) electrodes facing away from you, place the casting tray(s) (with gel(s)) back in the gel box(s). The top lane(s) should be on your left, as the DNA will move to the right."
      check "Using the graduated cylinder, add 50 mL of 1X TAE from J2 at A5.500 so that the surface of the gel is covered."
      check "Remove the comb(s) and place them in the appropriate box(s) in A7.325."
      check "Put the graduated cylinder back at A5.305."
      image "gel_fill_TAE_to_line"
    }

    show {
      title "Add loading dye"
      note "Add #{volume / 5.0} µL of loading dye to each (used) well of the stripwells"
      stripwells.each do |sw|
        bullet "Stripwell #{sw.id}, wells #{sw.non_empty_string}"
      end
    }

    show {
      title "Load DNA ladder"
      gels.each do |gel|
        check "Using a 100 µL pipetter, pipet 10 µL of ladder (containing loading dye) from tube #{ladder} into wells 1 (top-left) and 7 (bottom left) of gel #{gel}."
      end
      image "gel_begin_loading"
    }

    gels.each do |gel|
      gel.set 0, 0, ladder
      gel.set 1, 0, ladder
    end

    transfer( stripwells, gels ) {
      title "Using a 100 µL pipetter, pipet #{volume} µL of each PCR result into the indicated gel lane."
      note "Make sure each stripwell has the leftmost well labeled with an 'A'. 
            This well contains the first sample. The well to its right contains the second sample, etc."
      image "gel_begin_loading"
    }
    
    show {
      title "Start electrophoresis"
      note "Carefully attach the gel box lid(s) to the gel box(es), being careful not to bump the samples out of the wells. Attach the red electrode to the red terminal of the power supply, and the black electrode to the neighboring black terminal. Hit the start button on the gel boxes - usually a small running person icon."
      note "Make sure the power supply is not erroring (no E* messages) and that there are bubbles emerging from the platinum wires in the bottom corners of the gel box."
      image "gel_check_for_bubbles"
    }

    release stripwells # TODO throw these away

    release gels + [ ladder, dye ]

    return input

  end

end



