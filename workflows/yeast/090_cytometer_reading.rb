needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

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

  def arguments
    {
      io_hash: {},
      #Enter the item id that you are going to start overnight with
      yeast_deepwell_plate_ids: [21498],
      range_to_read: { from: [[1,1]], to: [[1,12]] },
      yeast_ubottom_plate_ids: [32316],
      read_volume: 100,
      debug_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    io_hash = { yeast_deepwell_plate_ids: [], yeast_ubottom_plate_ids: [], range_to_read: { from: [[1,1],[]], to: [[],[]] }, debug_mode: "No", read_volume: 100 }.merge io_hash
    yeast_deepwell_plates = io_hash[:yeast_deepwell_plate_ids].collect { |i| collection_from i }
    show {
      title "Protocol information"
      note "This protocol is used to take cytometer readings from deepwell plates using u-bottom plates."
      note "#{io_hash}"
    }
    if io_hash[:yeast_ubottom_plate_ids].empty?
      yeast_ubottom_plates = yeast_deepwell_plates.collect { produce new_collection "96 U-bottom Well Plate", 8, 12 }
      show {
        title "Grab #{yeast_ubottom_plates.length} 96 U-bottom Well Plate"
        note "Grab #{yeast_ubottom_plates.length} 96 U-bottom Well Plate and label with #{yeast_ubottom_plates.collect { |y| y.id }}."
      }
    else
      yeast_ubottom_plates = io_hash[:yeast_ubottom_plate_ids].collect { |i| collection_from i }
    end
    take yeast_deepwell_plates + yeast_ubottom_plates, interactive: true
    show {
      title "Vortex the deepwell plates."
      note "Gently vortex the deepwell plates #{deepwell_plates.collect { |d| d.id }} on a table top vortexer at settings 6 for about 20 seconds."
    }
    transfer( yeast_deepwell_plates, yeast_ubottom_plates, range_to_read: io_hash[:range_to_read], debug_mode: io_hash[:debug_mode] ) {
      title "Transfer #{io_hash[:read_volume]} µL"
      note "Using either 6 channel pipettor or single pipettor."
    }
    release yeast_deepwell_plates, interactive: true
    job_id = jid
    show {
      title "Cytometer reading"
      check "Go to the software, click Auto Collect tab, click Eject Plate if the CSampler holder is not outside. If Eject Plate button is not clickable, click Open Run Display first."
      check "Place the loaded u-bottom plate on the CSampler holder"
      check "Click new workspace, for Plate Type, choose 96 well plate: U-bottom. Choose all the wells you are reading, enter the following settings. Under Run Limits, 10000 events, 30 µL, check the check box for 30 µL. Under Fluidics, choose Fast. Under Set Threshold, choose FSC-H, enter 400000. Then Click Apply Settings, it will popup a window to prompt you to save as a new file, go find the My Documents/Aquarium folder and save the file as cytometry_#{job_id}. And the wells you just chose should turn to a different color."
      check "Click Open Run Display, then click Autorun."
    }
    show {
      title "Eject plate and export data"
      check "Wait till the cytometer says Done. Click Close Run Display, then click Eject Plate. Place the plate on a location near the cytometer if there are still unused wells. Discard the plate if all wells are used."
      check "Click File/Export ALL Samples as FCS"
      check "Go to Desktop/FCS Exports, find the folder you just exported, it should be the folder dated by most recent time. Click Send to/Compressed(zipped) folder, rename it as cytometry_#{job_id}. Upload this zip file here by dragging it here. After upload is done, delete the exported folder and zip file in the FCS Exports folder."
      upload var: "cytometry_#{job_id}"
    }
    show {
      title "Clean run"
      check "Click File/Open workspace or template, go to MyDocuments folder to find clean_regular_try.c6t file and open it."
      check "Go find the cleaning 24 well plate, check if there is still liquid left in tubes at D4, D5, D6 marked with C, D, S on tube lid top. If any tube has lower than 50 µL of liquid in it, replace each tube with a full reagnent tube with the same letter written on its lid top."
      check "Put the cleanning 24 well plate on the CSampler."
      check "Click Open Run Display, then click Autorun, it will prompt you save the file, click Save, then click Yes to replace the old file."
    }
    release yeast_ubottom_plates
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"cytometer read")
      end
    end
    io_hash[:yeast_ubottom_plates_ids] = yeast_ubottom_plates.collect {|d| d.id}
    return { io_hash: io_hash }
  end # main

end # Protocol

