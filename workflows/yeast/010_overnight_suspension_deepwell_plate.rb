needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the item id that you are going to start overnight with
      yeast_item_ids: [13011],
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL SC liquid (sterile)",
      #The volume of the overnight suspension to make
      volume: "1",
      debug_mode: "Yes",
      task_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode] || "No"
    io_hash[:task_mode] = input[:task_mode] || "No"
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    yeast_items = io_hash[:yeast_item_ids].collect {|yid| find(:item, id: yid )[0]}
    media_type = io_hash[:media_type]
    volume = io_hash[:volume]
    take yeast_items, interactive: true
    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from glycerol stocks, plates or overnight suspensions into Eppendorf Deepwell Plate 96"
    }
    deepwells = produce spread yeast_items, "Eppendorf Deepwell Plate 96", 12, 8
    load_samples( ["Yeast items"], [
        yeast_items,
      ], deepwells )
    release yeast_items, interactive: true
  end # main

end # Protocol
