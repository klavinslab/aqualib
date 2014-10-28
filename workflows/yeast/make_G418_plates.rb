needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      plasmid_ids: [9189,11546,11547],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    # if io_hash[:debug_mode].downcase == "yes"
    #   def debug
    #     true
    #   end
    # end
    x = debug_mode true
    show {
      note "#{x}"
    }
    plasmid_kan_ids = io_hash[:plasmid_ids].select { |pid| find(:item, id: pid)[0].sample.properties["Yeast Marker"].downcase[0,3]== "kan"}
    num = plasmid_kan_ids.length
    show {
    	title "Grab YPAD plates and G418 stock"
      check "Grab #{num} YPAD plates."
      check "Grab #{(num*300/1000.0).ceil} 1 mL G418 stock in M20."
      check "Waiting for the G418 stock to thaw."
      check "Use sterile beads to spread 300 µL of G418 to each YPAD plates, mark each plate with G418."
      check "Place the plates with agar side down in the dark fume hood to dry."
    }
    return { io_hash: io_hash }
  end # main

end # Protocol