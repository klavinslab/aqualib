needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol
  
  include Standard
  include Cloning
  
  def arguments
    {
      io_hash: {},
      yeast_ids: [2701, 2697, 2720],
      debug_mode: "Yes",
    }
  end
  
  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = {yeast_ids: [2701, 2697], debug_mode: "No", item_choice_mode: "No"}.merge io_hash
    io_hash[:yeast_ids].each do |yid|
      x = find(:sample,{id: yid})[0].in("Yeast Glycerol Stock")[0]
      show{
        title "Yeast Glycerol Stock id #{x}"
      }
    end
  end
  
end
