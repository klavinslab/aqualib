needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def move items, new_location
    # takes items (array or single objects) and move locations to new_location
    new_location = new_location.to_s
    items = [items] unless items.kind_of?(Array)
    items.each do |i|
      raise "Must be Item or Array of Items to move" unless i.class == Item
      i.location = new_location
      i.save
    end
  end # move

  def delete items
    # invoke mark_as_deleted for each item in items
    items = [items] unless items.kind_of?(Array)
    items.each do |i|
      raise "Must be Item or Array of Items to delete" unless i.class == Item
      i.mark_as_deleted
      i.save
    end
  end # delete

  def arguments
    {
      io_hash: {},
      ids: [30437,30473],
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
    take items, interactive: true
    samples = items.collect { |i| i.sample }
    show {
      title "Test page"
      note items.collect { |i| "#{i.class}"}
    }
    move items, "30 C incubator"
    move items[0], "456 incuabtor"
    delete items
    release items, interactive: true
  end
end
