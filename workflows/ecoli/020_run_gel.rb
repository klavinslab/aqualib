needs "aqualib/lib/standard"

class Protocol

  include Standard

    def transfer sources, destinations, options={}

      # go through each well of the sources and transfer it to the next empty well of
      # destinations. Every time a source or destination is used up, advance to 
      # another step.    

      opts = { skip_non_empty: true }.merge options

      if block_given?
        user_shows = ShowBlock.new.run(&Proc.new) 
      else
        user_shows = []
      end

      # source and destination indices
      s=0
      d=0

      # matrix indices
      sr,sc = 0,0
      dr,dc = 0,0
      unless destinations[0].matrix[dr][dc] == -1
        dr,dc = destinations[0].next 0, 0, skip_non_empty: true
      end

      routing = []

      while sr != nil

        # add to routing table
        routing.push({from:[sr,sc],to:[dr,dc]})

        # increase sr,sc,dr,dc
        sr,sc =      sources[s].next sr, sc, skip_non_empty: false
        dr,dc = destinations[d].next dr, dc, skip_non_empty: true

        # if either is nil or if the source well is empty
        if !sr || !dr || sources[s].matrix[sr][sc] == -1

          # display 
          show {
            title "Transfer from #{sources[s].object_type.name} #{sources[s].id} to #{destinations[d].object_type.name} #{destinations[d].id}"
            transfer sources[s], destinations[d], routing
            raw user_shows
          }

          # update destination collection
          routing.each do |r|
            destinations[d].set r[:to][0], r[:to][1], Sample.find(sources[s].matrix[r[:from][0]][r[:from][1]])
          end

          destinations[d].save

          # clear routing for next step
          routing = []

          if sr && sources[s].matrix[sr][sc] == -1
            s += 1
            return unless s < sources.length
            sr,sc = 0,0
          end

          # update source indices
          if !sr
            s += 1
            return unless s < sources.length 
            sr,sc = 0,0
          end

          # update destination indices
          if !dc
            d += 1
            return unless d < destinations.length
            dr,dc = 0,0
            unless destinations[d].matrix[dr][dc] == -1
              dr,dc = destinations[d].next 0, 0, skip_non_empty: true
            end
          end

        end

      end

      return

    end # transfer

  def arguments
    {
      io_hash: {},
      stripwell_ids: [28339],
      gel_ids: [28276],
      volume: 50       # The volume of PCR fragment to load in µL
    }
  end

  def main

    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    stripwells = io_hash[:stripwell_ids].collect { |i| collection_from i }
    gels = io_hash[:gel_ids].collect { |i| collection_from i }
    volume = input[:volume] || 50

    if io_hash[:debug_mode] == "Yes"
      def debug
        true
      end
    end

    take stripwells + gels, interactive: true

    ladder = choose_sample "1 kb Ladder"
    dye = choose_object "Gel Loading Dye Blue (6X)"

    take [ladder] + [dye], interactive: true

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
      #gel.set 1, 0, ladder
      if gel.dimensions[0] == 2
        gel.set 1, 0, ladder 
      end
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

    show {
      title "Clean up"
      note "Discard the empty stripwells"
      stripwells.each do |stripwell|
        stripwell.mark_as_deleted
      end
    }

    release gels
    release [ ladder, dye ], interactive: true

    io_hash[:fragment_construction_task_ids].each do |tid|
      ready_task = find(:task, id: tid)[0]
      set_task_status(ready_task,"gel run")
    end
    
    return { io_hash: io_hash }
  end

end



