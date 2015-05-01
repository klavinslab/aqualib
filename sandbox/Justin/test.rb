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
    ygc = io_hash[:yeast_ids].collect {|y| choose_sample find(:sample,{id: y})[0].name, object_type: "Yeast Plate"}
    tab = [["Glycerol Stock id", "Loction"]]
    take ygc, interactive: true, method: "boxes"
  end
  
end