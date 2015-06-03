needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

# please use the sample id (not the item id) as suffix when ordering primers from IDT.

class Protocol

  include Standard
  include Cloning
  require 'set'

  def debug
    false
  end

  def arguments
    {
      io_hash: {},
      debug_mode: "No",
      primer_ids: [4360,4344,6089,5979],
      group: "cloning"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { primer_ids: [], order_number: "" }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    io_hash[:primer_ids].sort!

    show {
      title "Go the biochem store to pick up primers"
      note "Walk accross the campus to the biochem store to pick up primers."
      note "Abort this protocol if no primer is showed up. It will automatically rescheduled."
    }

    show {
      title "Quick spin down all the primer tubes"
      note "Find the order with sales order (or supplier ref) number #{io_hash[:order_number]}"
      note "Put all the primer tubes in a table top centrifuge to spin down for 3 seconds."
      warning "Make sure to balance!"
    }

    mw = show {
      title "Enter the MW of the primer"
      note "Enter the number of moles for each primer, in nm. This is written toward the bottom of the tube, below the MW. The id of the primer is listed before the primer's name on the side of the tube."
      io_hash[:primer_ids].each do |prid|
        get "number", var: "mw_#{prid}", label: "Primer #{prid}", default: 10
      end
    }

    primer_stocks = []
    primer_stocks_to_dilute = []
    primer_aliquots = []

    tab = [["Primer ids", "Primer Stock ids", "Rehydrate"]]

    io_hash[:primer_ids].each do |prid|

      primer_stock = produce new_sample find(:sample, id: prid)[0].name, of: "Primer", as: "Primer Stock"
      primer_stocks.push primer_stock

      rehydrate_volume = mw[:"mw_#{prid}".to_sym] * 10
      if primer_stock.sample.properties["Anneal Sequence"][1] != "*"
        rehydrate_volume = rehydrate_volume.to_s + " µL of TE"
        primer_stocks_to_dilute.push primer_stock
      else
        rehydrate_volume = rehydrate_volume.to_s + " µL of water"
      end

      tab.push([prid, "#{primer_stock}", rehydrate_volume])

    end

    show {
      title "Label and rehydrate"
      note "Label each primer tube with the ids shown in Primer Stock ids and rehydrate with volume of TE or water shown in Rehydrate"
      table tab
    }

    if primer_stocks.length > 0
      show {
        title "Vortex and centrifuge"
        note "Wait one minute for the primer to dissolve in TE." if primer_stocks.length < 7
        note "Vortex each tube on table top vortexer for 5 seconds and then quick spin for 2 seconds on table top centrifuge."
      }
    end

    if primer_stocks_to_dilute.length > 0
      primer_aliquots = primer_stocks_to_dilute.collect { |p| produce new_sample p.sample.name, of: "Primer", as: "Primer Aliquot" }
      show {
        title "Grab #{primer_aliquots.length} 1.5 mL tubes"
        check "Grab #{primer_aliquots.length} 1.5 mL tubes, label with following ids."
        check primer_aliquots.collect { |p| "#{p}"}
        check "Add 90 µL of water into each above tube."
      }
      show {
        title "Make primer aliquots"
        note "Add 10 µL from primer stocks into each primer aliquot tube using the following table."
        table [["Primer Aliquot id", "Primer Stock, 10 µL"]].concat (primer_aliquots.collect { |p| "#{p}"}.zip primer_stocks_to_dilute.collect { |p| { content: p.id, check: true } })
      }
    end

    release primer_stocks + primer_aliquots, interactive: true,  method: "boxes"

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"received and stocked")
      end
    end

    return { io_hash: io_hash }

  end

end
