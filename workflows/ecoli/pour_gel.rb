needs "aqualib/lib/standard"

class Protocol

  include Standard

  def arguments
    {
      io_hash: {},
      comb_1: "6 thick",
      comb_2: "6 thick",
      percentage: 1,
      stripwell_ids: [30632],
      debug_mode: "No"
    }
  end

  def main

    #   percentage: number, "Enter the percentage gel to make (e.g. 1 = 1%)"
    #   comb_1, comb_2: string, Enter '0' for no lanes,  "Enter '6 thin' for 6 thin lanes. Enter '6 thick' for 6 thick lanes. Enter '10 thin' for 10 thin lanes. Enter '10 thick' for 10 thick lanes"
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    # re define the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    
    comb_1 = io_hash[:comb_1] || "6 thick"
    comb_2 = io_hash[:comb_2] || "6 thick"
    comb_1 = comb_1.split(' ')
    comb_2 = comb_2.split(' ')
    comb_1[0] = comb_1[0].to_i
    comb_2[0] = comb_2[0].to_i
    raise "Incorrect inputs, comb_1 and comb_2 should be the same size, both 6 or 10. You can choose thin or thick for each one though" if comb_2[0] != 0 && comb_1[0] != comb_2[0]
    percentage = io_hash[:percentage] || 1
    stripwells = io_hash[:stripwell_ids].collect { |sid| collection_from sid }

    take stripwells

    num_samples = stripwells.inject(0) { |sum,sw| sum + sw.num_samples }
    cols = comb_1[0]
    if comb_2[0] == 0
      num_wells_per_gel = comb_1[0] - 1
      rows = 1
    else
      num_wells_per_gel = comb_1[0] - 1 + comb_2[0] - 1
      rows = 2
    end

    num_gels = ( num_samples / num_wells_per_gel.to_f ).ceil

    show {
      title "#{num_gels} 50 mL agarose gel(s) for #{num_samples} sample(s)"
      note "This protocol produces gels to be used to run samples in stripwells #{stripwells.collect { |s| s.id }}"
      note "This protocol should be run in the gel room. If you are not there, log out, go to the gel room, and log in there to run this protocol. It will be under 'Protocols > Pending Jobs'."
    }

    gel_volume = 50.0
    agarose_mass = (percentage / 100.0) * gel_volume
    error = (agarose_mass * 0.05).round 5

    gel_ids = []

    (1..num_gels).each do |gel_number|
    
      show {
        title "Pour gel"
        check "Grab a flask from on top of the microwave M2."
        check "Using a digital scale, measure out #{agarose_mass} g (+/- #{error} g) of agarose powder and add it to the flask."
        check "Get a graduated cylinder from on top of the microwave. Measure and add 50 mL of 1X TAE from jug J2 to the flask."
        check "Use a paper towel to handle the flask. Microwave 70 seconds on high in microwave M2, then swirl. The agarose should now be in solution."
        note "If it is not in solution, microwave 7 seconds on high, then swirl. Repeat until dissolved."
        warning "Work in the gel room, wear gloves and eye protection all the time"
      }

      show {
        title "Add 5 µL GelGreen"
        note "Using a 10 µL pipetter, take up 5 µL of GelGreen into the pipet tip. Expel the GelGreen directly into the molten agar (under the surface), then swirl to mix."
        warning "GelGreen is supposedly safe, but stains DNA and can transit cell membranes (limit your exposure)."
        warning "GelGreen is photolabile. Limit its exposure to light by putting it back in the box."
        # image "gel_add_gelgreen"
      }

      show {
        title "Gel Number #{gel_number}, add top comb"
        check "Go get a 49 mL Gel Box With Casting Tray (clean)"
        check "Retrieve a #{comb_1[0]}-well purple comb from A7.325"
        check "Position the gel box with the electrodes facing away from you. Add a purple comb to the side of the casting tray nearest the side of the gel box."
        check "Put the #{comb_1[1]} side of the comb down."
        note "Make sure the comb is well-situated in the groove of the casting tray."
        # image "gel_comb_placement"
      }

      unless comb_2[0] == 0
        show {
          title "Gel Number #{gel_number}, add bottom comb"
          check "Retrieve a #{comb_2[0]}-well purple comb from A7.325"
          check "Position the gel box with the electrodes facing away from you. Add a purple comb to the center of the casting tray."
          check "Put the #{comb_2[1]} side of the comb down."
          note "Make sure the comb is well-situated in the groove of the casting tray."
        # image "gel_comb_placement"
        }
      end

      gel = produce new_collection "50 mL #{percentage} Percent Agarose Gel in Gel Box", rows, cols
      gel.move "A7.325"

      show {
        title "Pour and label the gel"
        note "Using a gel pouring autoclave glove, pour agarose from one flask into the casting tray. Pour slowly and in a corner for best results. Pop any bubbles with a 10 µL pipet tip."
        note "Write id #{gel} on piece of lab tape and affix it to the side of the gel box."
        note "Leave the gel to location A7.325 to solidify."
        # image "gel_pouring"
      }

      release [ gel ]

      gel_ids.push gel.id

    end

    show {
      title "Clean up!"
      check "Place the graduated cylinder back on top of microwave M2."
      check "Place the flask back on top of microwave M2."
    }

    release stripwells

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        # set_task_status(task,"pcr")
        task.notify "gel poured", job_id: jid
        task.save
      end
    end

    io_hash[:gel_ids] = gel_ids

    return { io_hash: io_hash }

  end

end

