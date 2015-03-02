needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"



class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      "ids Yeast Plate"=> [22673,22674,22675],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode] || "No"

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    items = io_hash[:ids].collect {|id| find(:item, id:id)[0]}

    # items = find(:item, { object_type: { name: "E coli Plate of Plasmid" } })

    take items, interactive: true

    items.each do |i|
      i.store
      i.reload
    end

    release items, interactive: true, method: "boxes"



  end # main
end # Protocol
