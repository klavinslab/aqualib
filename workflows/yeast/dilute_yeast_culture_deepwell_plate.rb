needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def inducer_volume_item conc_inducer, master_volume
    conc_inducer_arr = conc_inducer.split(" ").map(&:strip)
    conc = conc_inducer_arr[0].to_f
    
    if conc == 0
      return {
        volume: 0
      }
    end
    
    unit = conc_inducer_arr[1]
    inducer_name = conc_inducer_arr[2].downcase

    unit_map = {
      "pM" => "nM",
      "nM" => "uM",
      "uM" => "mM",
      "ug/mL" => "mg/mL"
    }

    inducer_sample = find(:sample, name: inducer_name)[0]

    if conc < 0.1
      raise "conc less than 0.1 is not allowed."
    elsif conc < 1
      volume = conc * 10
      inducer = inducer_sample.in("100 #{unit} stock")[0]
    elsif conc < 10
      volume = conc
      inducer = inducer_sample.in("1 #{unit_map[unit]} stock")[0]
    elsif conc < 100
      volume = conc/10
      inducer = inducer_sample.in("10 #{unit_map[unit]} stock")[0]
    elsif conc < 1000
      volume = conc/100
      inducer = inducer_sample.in("100 #{unit_map[unit]} stock")[0]
    elsif conc < 10000
      volume = conc/1000
      inducer = inducer_sample.in("1 #{unit_map[unit_map[unit]]} stock")[0]
    else
      raise "conc greater than 10000 is not allowed."
    end

    volume = volume*master_volume/1000

    return {
      volume: volume,
      inducer: inducer
    }
  end

  def process_inducer inducer_additions, master_volume

    # Process inducer_addition text and return volume and item_id in inducer_instructions and required inducers to take in inducers

    inducers, instructions = [], []
    inducer_additions.each do |inducer_addition|
      instruction = []
      if ["0", "None", 0, "none", "N/A"].include? inducer_addition
        instruction.push "None"
      else
        conc_inducers = inducer_addition.split("and").map(&:strip)
        conc_inducers.each do |conc_inducer|
          if !(["0", "None", 0, "none", "N/A"].include? conc_inducer)
            result = inducer_volume_item conc_inducer, master_volume
            if result[:volume] > 0
              instruction.push "#{result[:volume]} µL of #{result[:inducer].id}"
              inducers.push result[:inducer]
            end
          end
        end
      end
      instructions.push instruction.join(" and ")
    end

    inducers.uniq!

    return {
      instructions: instructions,
      inducers: inducers
    }
  end

  def transfer sources, destinations, options={}

     # go through each well of the sources and transfer it to the next empty well of
     # destinations. Every time a source or destination is used up, advance to
     # another step.

     opts = { skip_non_empty: true, range_to_read: { from: [[1,1],[]], to: [[],[]] }, debug_mode: "No" }.merge options

     if block_given?
       user_shows = ShowBlock.new.run(&Proc.new)
     else
       user_shows = []
     end

     # source and destination indices
     s=0
     d=0

     # matrix indices
     sr,sc = (opts[:range_to_read][:from][0][0]||1)-1,(opts[:range_to_read][:from][0][1]||1)-1
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

       sr_end, sc_end = sources[s].next (opts[:range_to_read][:to][s][0]||0)-1, (opts[:range_to_read][:to][s][1]||0)-1, skip_non_empty: false

       show {
        note "source location "+"#{[sr,sc]}"
        note "dest location "+"#{[dr,dc]}"
        note "source "+"#{s}"
        note "dest "+"#{d}"
        note "from "+"#{[(opts[:range_to_read][:from][s][0]||1)-1,(opts[:range_to_read][:from][s][1]||1)-1]}"
        note "to "+"#{[(opts[:range_to_read][:to][s][0]||0)-1,opts[:range_to_read][:to][s][1]]}"
       } if opts[:debug_mode].downcase == "yes"

       # if either is nil or if the source well is empty or if the source well has reached its range
       if !sr || !dr || sources[s].matrix[sr][sc] == -1 || [sr,sc] == [sr_end, sc_end]

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

         # BUGFIX by Yaoyu Yang
         # return if sources[s].matrix[sr][sc] == -1
         #
         if (sr && sources[s].matrix[sr][sc] == -1) or !sr or [sr,sc] == [sr_end, sc_end]
           s += 1
           return unless s < sources.length
           sr,sc = (opts[:range_to_read][:from][s][0]||1)-1,(opts[:range_to_read][:from][s][1]||1)-1
         end
         # END BUGFIX

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

  def range_of_adding yeast_deepwell_plate_ids, range_to_read
    num_of_wells = []
    yeast_deepwell_plate_ids.each_with_index do |p, idx|
      plate = collection_from p
      num_of_row = plate.matrix[0].length
      num_of_well = 0
      if range_to_read[:to][idx].length == 0
        num_of_well = plate.num_samples
      else
        num_of_well = (range_to_read[:to][idx][0] - range_to_read[:from][idx][0]) * num_of_row
        num_of_well += (range_to_read[:to][idx][1] - range_to_read[:from][idx][1]) + 1
      end
      num_of_wells.push num_of_well
    end
    return num_of_wells
  end

  def arguments
    {
      io_hash: {},
      yeast_deepwell_plate_ids: [33514],
      media_type: "800 mL SC liquid (sterile)",
      volume: 1000,
      dilution_rate: 0.01,
      new_inducers: ["400 ug/mL zeocin", "10 nM b-e and 20 uM auxin", "20 uM auxin", "10 nM b-e", "20 uM auxin", "10 nM b-e", "20 uM auxin", "10 nM b-e", "0", "10 nM b-e", "0", "10 nM b-e"],
      range_to_dilute: { from: [[2,1]], to: [[2,12]] },
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", new_inducers: [], when_to_add_inducer: "start, dilute", range_to_dilute: { from: [[1,1],[]], to: [[],[]] } }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash = { yeast_deepwell_plate_ids: [] }.merge io_hash
    deepwell_plates = io_hash[:yeast_deepwell_plate_ids].collect { |i| collection_from i }
    yeast_deepwell_plates = deepwell_plates.collect { produce new_collection "Eppendorf 96 Deepwell Plate", 8, 12 }
    take deepwell_plates, interactive: true
    num_of_wells = range_of_adding io_hash[:yeast_deepwell_plate_ids], io_hash[:range_to_dilute]
    show {
      title "Take new deepwell plates"
      note "Grab #{yeast_deepwell_plates.length} Eppendorf 96 Deepwell Plate. Label with #{yeast_deepwell_plates.join(", ")}."
      yeast_deepwell_plates.each_with_index do |y,idx|
        note "Add #{io_hash[:volume]*(1-io_hash[:dilution_rate])} µL of #{io_hash[:media_type]} into first #{num_of_wells[idx]} wells."
      end
    }
    show {
      title "Vortex the deepwell plates."
      note "Gently vortex the deepwell plates #{deepwell_plates.join(", ")} on a table top vortexer at settings 6 for about 20 seconds."
    }

    transfer(deepwell_plates, yeast_deepwell_plates, range_to_read: io_hash[:range_to_dilute]) {
      title "Transfer #{io_hash[:volume]*io_hash[:dilution_rate]} µL"
      note "Using either 6 channel pipettor or single pipettor."
    }

    io_hash[:inducer_additions] = []

    if io_hash[:new_inducers].length > 0
      io_hash[:inducer_additions] = io_hash[:new_inducers]
    else
      io_hash[:inducers].each_with_index do |inducer_array,idx|
        inducer_array.each do |inducer|
          if io_hash[:when_to_add_inducer][idx].include? "dilute"
            io_hash[:inducer_additions].push inducer
          else
            io_hash[:inducer_additions].push "None"
          end
        end
      end
    end

    list_of_items = []
    list_of_volumes = []
    results = process_inducer io_hash[:inducer_additions], io_hash[:volume]

    take results[:inducers], interactive: true, method: "boxes"

    load_samples_variable_vol( ["Inducers"], [
        results[:instructions]
      ], yeast_deepwell_plates )

    show {
      title "Seal the deepwell plate(s) with a breathable sealing film"
      note "Put a breathable sealing film on following deepwell plate(s) #{yeast_deepwell_plates.join(", ")}."
      note "Place the deepwell plate(s) into the 30 C shaker incubator, make sure it is secure."
    }

    show {
      title "Place the deepwell plates in the washing station"
      note "Place the following deepwell plates #{deepwell_plates.join(", ")} in the washing station "
    }

    deepwell_plates.each do |d|
      d.mark_as_deleted
      d.save
    end

    yeast_deepwell_plates.each do |d|
      d.location = "30 C shaker incubator"
      d.save
    end

    release yeast_deepwell_plates

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"diluted")
      end
    end

    io_hash[:yeast_deepwell_plate_ids] = yeast_deepwell_plates.collect { |d| d.id }
    return { io_hash: io_hash }
  end # main
end # main
