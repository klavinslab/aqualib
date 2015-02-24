needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      item_ids: [14251,14250],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    items = io_hash[:item_ids].collect { |x| find(:item, id: x)[0] }
    take items, interactive: true, method: "boxes"
    location = show {
      title "Enter new location for each item"
      items.each do |x|
        get "text", var: "c#{x.id}", label: "Enter new location for item #{x.id}", default: "Klavins Lab"
      end
    }

    items.each do |x|
      x.location = location[:"c#{x.id}".to_sym]
      x.save
    end

    release items, interactive: true, method: "boxes"

    return { io_hash: io_hash }
  end # main

end