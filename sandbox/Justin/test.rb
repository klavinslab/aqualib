needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol
  
  include Standard
  include Cloning
  
  def arguments
    {
      io_hash: {},
      sample_ids: [6236, 6235],
      debug_mode: "Yes",
    }
  end
  
  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    ygc = io_hash[:sample_ids].collect {|y| choose_sample find(:sample,{id: y})[0].name, object_type: "Plasmid Stock"}
    take ygc, interactive: true, method: "boxes"
  end
  
end
