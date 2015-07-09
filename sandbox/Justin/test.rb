needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol
  
  include Standard
  include Cloning
  
  def arguments
    {
      io_hash: {},
      plasmid_ids: [7869],
      debug_mode: "No",
    }
  end
  
  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = {sample_ids: [2701, 2697], debug_mode: "No", item_choice_mode: "No"}.merge io_hash
    ps = io_hash[:sample_ids].collect {|y| choose_sample find(:sample,{id: y})[0].name, object_type: "Plasmid Stock"}
  end
  
end
