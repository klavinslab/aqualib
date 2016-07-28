needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      gel_slice_ids: [74490, 74491, 74492, 74493, 74494, 74495],
      silent_slice_take: true,
      task_ids: [25364, 25365],
      debug_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", gel_slice_ids: [], silent_slice_take: false }.merge io_hash # set default value of io_hash

    # redefine the debug function based on the debug_mode input
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    if io_hash[:gel_slice_ids].length == 0
      show {
        title "No gel slices need to be purified"
        note "No gel slices need to be worked on. Thanks for your efforts!"
      }
    else
      gel_slices = find(:item, id: io_hash[:gel_slice_ids])
      gel_slice_lengths = gel_slices.collect { |gs| gs.sample.properties["Length"] }

      num = gel_slices.length
      num_arr = *(1..num)

      predicted_time = time_prediction io_hash[:gel_slice_ids].length, "purify_gel"

      show {
        title "Protocol Information"
        note "This protocol purfies gel slices into DNA fragment stocks."
        note "The following gel slices are going to be purfied"
        note gel_slices.collect { |gs| "#{gs}" }
        note "The predicted time needed is #{predicted_time} min."
      }

      if io_hash[:silent_slice_take]
        take gel_slices
      else
        take gel_slices, interactive: true,  method: "boxes"
      end

      qg_volumes = gel_slices.collect { |gs| (gs.associations["weight"] * 3000).floor }
      iso_volumes = gel_slices.collect { |gs| (gs.associations["weight"] * 1000).floor }
      gel_slices.each_with_index do |gs,idx|
         if gs.sample.properties["Length"] > 500 && gs.sample.properties["Length"] < 4000
          iso_volumes[idx] = 0
         end
      end
      total_volumes = (0...gel_slices.length).map { |idx| qg_volumes[idx] + iso_volumes[idx] }

      show {
        title "Move gel slices to new tubes"
        note "Please carefully transfer the gel slices in the following tubes each to a new 2.0 mL tube using a pipette tip:"
        note gel_slices.select.with_index { |gs, idx| total_volumes[idx] > 1500 && total_volumes[idx] < 2000 }.map { |gs| "#{gs}" }.join(", ")
        note "Label the new tubes accordingly, and discard the old 1.5 mL tubes."
      } if total_volumes.any? { |v| v > 1500 && v < 2000 }

      show {
        title "Add the following volumes of QG buffer to the corresponding tube."
        table [["Gel Slices", "QG Volume in µL"]].concat(gel_slices.collect {|s| s.id}.zip qg_volumes.collect { |v| { content: v, check: true } })
      }

      show {
        title "Place all tubes in 50 degree heat block"
        timer initial: { hours: 0, minutes: 10, seconds: 0}
        note "Vortex every few minutes to speed up the process."
        note "Retrieve after 10 minutues or until the gel slice is competely dissovled."
      }

      tubes_in_two = gel_slices.select.with_index { |gs, idx| total_volumes[idx] >= 2000 }.map { |gs| "#{gs}" }.join(", ")
      show {
        title "Equally distribute melted gel slices between tubes"
        note "Please equally distribute the volume of the following tubes each between two 1.5 mL tubes:"
        note tubes_in_two
        note "Label the new tubes accordingly, and discard the old 1.5 mL tubes."
      } if !tubes_in_two.empty?

      show {
        title "Add isopropanol"
        note "Add isopropanol according to the following table. Pipette up and down to mix."
        warning "Divide the isopropanol volume evenly between two 1.5 mL tubes (#{tubes_in_two}) since you divided one tube's volume into two earlier." if !tubes_in_two.empty?
        table [["Gel slice id", "Isopropanol (µL)"]].concat(gel_slices.collect {|s| s.id}.zip(iso_volumes.collect { |v| { content: v, check: true } }).reject { |r| r[1] == { content: 0, check: true } })
       } if (iso_volumes.select { |v| v > 0 }).length > 0

      show {
        title "Prepare the centrifuge"
        check "Grab #{num} of pink Qiagen columns, label with 1 to #{num} on the top."
        check "Add tube contents to LABELED pink Qiagen columns using the following table."
        check "Be sure not to add more than 750 µL to each pink column."
        table [["Gel slices id", "Qiagen column"]].concat(gel_slices.collect {|s| s.id}.zip num_arr)
      }

      show {
        title "Centrifuge"
        check "Spin at 17.0 xg for 1 minute to bind DNA to columns"
        check "Empty collection columns by pouring waste liquid into waste liquid container."
        check "Add 750 µL PE buffer to columns and wait five minutes"
        check "Spin at 17.0 xg for 30 seconds to wash columns."
        check "Empty collection tubes."
        check "Add 500 µL PE buffer to columns and wait five minutes"
        check "Spin at 17.0 xg for 30 seconds to wash columns"
        check "Empty collection tubes."
        check "Spin at 17.0 xg for 1 minute to remove all PE buffer from columns"
      }

      fragment_stocks = gel_slices.collect { |gs| gs.sample.make_item "Fragment Stock" }

      show {
        title "Use label printer to label new 1.5 mL tubes"
        check "Ensure that the B33-143-492 labels are loaded in the printer. This number should be displayed on the printer. If not, check with a lab manager."
        check "Open the LabelMark 6 software."
        check "Select \"Open\" --> \"File\" --> \"Serialized data top labels\""
        note "If an error about the printer appears, press \"Okay\""
        check "Select the first label graphic, and click on the number in the middle of the label graphic."
        check "On the toolbar on the left, select \"Edit serialized data\""
        check "Enter #{fragment_stocks[0].id} for the Start number and #{fragment_stocks.length} for the Total number, and select \"Finish\""
        check "Select \"File\" --> \"Print\" and select \"BBP33\" as the printer option."
        check "Press \"Print\" and collect the labels."
        image "purify_gel_edit_serialized_data"
        image "purify_gel_sequential"
      }

      show {
        title "Transfer to 1.5 mL tube"
        check "Apply the labels to the tubes."
        check "Transfer pink columns to the labeled tubes using the following table."
        table [["Qiagen column","1.5 mL tube"]].concat(num_arr.zip fragment_stocks.collect { |fs| { content:fs.id, check: true } })
        check "Add 30 µL molecular grade water or EB elution buffer to center of the column."
        warning "Be very careful to not pipette on the wall of the tube."
      }

      concs = show {
        title "Measure DNA Concentration"
        check "Elute DNA into 1.5 mL tubes by spinning at 17.0 xg for one minute, keep the columns."
        check "Pipette the flow through (30 µL) onto the center of the column, spin again at 17.0 xg for one minute. Discard the columns this time."
        check "Go to B9 and nanodrop all of 1.5 mL tubes, enter DNA concentrations for all tubes in the following:"
        fragment_stocks.each do |fs|
          get "number", var: "c#{fs.id}", label: "Enter a concentration (ng/µL) for tube #{fs}", default: 30.2
          get "text", var: "comment#{fs.id}", label: "Leave comments below."
        end
      }

      discard_stock = show {
        title "Decide whether to keep dilute stocks"
        note "The below stocks have a concentration of less than 10 ng/µL."
        note "Talk to a lab manager to decide whether or not to discard the following stocks."
        fragment_stocks.select { |fs| concs[:"c#{fs.id}".to_sym] < 10 }.each { |fs|
                                                                              select ["Yes", "No"], var: "d#{fs.id}", label: "Discard Fragment Stock #{fs}?"
                                                                              }
      } if fragment_stocks.any? { |fs| concs[:"c#{fs.id}".to_sym] < 10 }

      fragment_stocks_to_discard = discard_stock ? fragment_stocks.select { |fs| discard_stock[:"d#{fs.id}".to_sym] == "Yes" } : []
      if fragment_stocks_to_discard.any?
        show {
          title "Discard fragment stocks"
          note "Discard the following fragment stocks:"
          note fragment_stocks_to_discard.map { |fs| "#{fs}" }.join(", ")
        }
        fragment_stocks = fragment_stocks - fragment_stocks_to_discard
        delete fragment_stocks_to_discard
      end

      fragment_stocks.each_with_index do |fs, idx|
        fs.datum = { concentration: concs[:"c#{fs.id}".to_sym], volume: 28, volume_verified: "Yes" }
        fs.notes = [gel_slices[idx].notes, "Comment from purify_gel (#{jid}): " + concs[:"comment#{fs.id}".to_sym]].join(", ")
        fs.save
      end
      # Give a touch history in log
      take fragment_stocks
      release fragment_stocks, interactive: true, method: "boxes"
      io_hash[:fragment_stock_ids] = fragment_stocks.collect{ |fs| fs.id }
    end

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        notifs = []
        produced_fragment_stocks = []
        fragment_ids = task.simple_spec[:fragments]
        produced_fragment_ids = fragment_stocks.collect { |fs| fs.sample.id } & fragment_ids
        if produced_fragment_ids.empty?
          set_task_status(task,"failed")
        else
          set_task_status(task,"done")
        end
        failed_fragment_ids = fragment_ids - produced_fragment_ids
        failed_fragment_ids.each { |id| notifs.push "This task failed to produce a Fragment Stock for #{item_or_sample_html_link id, :sample}" }
        produced_fragment_stocks = fragment_stocks.select { |fs| produced_fragment_ids.include? fs.sample.id }
        produced_fragment_stocks.compact!
        produced_fragment_stocks.each { |fragment_stock| 
                                        notifs.push "This task produces Fragment Stock #{fragment_stock} (conc: #{fragment_stock.datum[:concentration]} ng/µL) for #{sample_html_link fragment_stock.sample}"
                                        notifs.push "The following comment was left on Fragment Stock #{fragment_stock}: #{fragment_stock.notes}" if fragment_stock.notes != ""
                                      }
        notifs.each { |notif| task.notify notif, job_id: jid }
      end
    end

    if gel_slices
      #delete gel_slices
      release gel_slices
    end

    return { io_hash: io_hash }

  end # main

end # Protocol
