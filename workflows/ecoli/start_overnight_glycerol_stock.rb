needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      glycerol_stock_ids: [8763,8759,8752],
      debug_mode: "Yes",
      group: "cloning"
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    # making sure have the following hash indexes.
    io_hash = { glycerol_stock_ids: [] }.merge io_hash

    overnights = []
    overnights = io_hash[:glycerol_stock_ids].collect { |id| produce new_sample find(:item, id: id)[0].sample.name, of: "Plasmid", as: "TB Overnight of Plasmid" }
    overnights.each_with_index do |x, idx|
      x.datum = { from: io_hash[:glycerol_stock_ids][idx] }
      x.save
    end

    overnight_marker_hash = Hash.new {|h,k| h[k] = [] }
    overnights.each do |x|
      marker_key = "TB"
      x.sample.properties["Bacterial Marker"].split(',').each do |marker|
        marker_key = marker_key + "+" + formalize_marker_name(marker)
      end
      overnight_marker_hash[marker_key].push x
    end

    overnight_marker_hash.each do |marker, overnight|
      show {
        title "Media preparation in media bay"
        check "Grab #{overnight.length} of 14 mL Test Tube"
        check "Add 3 mL of #{marker} to each empty 14 mL test tube using serological pipette"
        check "Write down the following ids on cap of each test tube using dot labels #{overnight.collect {|x| x.id}}"
      }
    end

    glycerol_stocks = io_hash[:glycerol_stock_ids].collect { |id| find(:item, id: id)[0] }
    take glycerol_stocks

    tab = [["Glycerol stock id", "Location", "Overnight id"]]
    glycerol_stocks.each_with_index do |g,idx|
      tab.push [g.id, { content: g.location, check: true }, { content: glycerol_overnights[idx].id, check: true } ]
    end

    show {
      title "Inoculation from glycerol stock"
      note "Extremely careful about sterile technique in this step!!!"
      check "Grab one glycerol stock at a time! Use a pipettor with a 100 µL sterile tip to vigerously scrape the glycerol stock to get a chunk of stock, add and mix into the 14 mL overnight tubes according to the following table. Return glycerol stock immediately after use."
      table tab
    }

    overnights.each do |o|
      o.location = "37 C shaker incubator"
      o.save
    end
    release glycerol_stocks + overnights, interactive: true

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id:tid)[0]
        set_task_status(task,"overnight")
      end
    end

    io_hash[:overnight_ids] = overnights.collect { |o| o.id }

    return { io_hash: io_hash }

  end # main
end # Protocol
