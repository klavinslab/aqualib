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
    debug_mode true 
    show {
      note "#{debug_mode true}"
    }
    show {
    	title "Grab YPAD plates and G418 stock"
    }


  end # main

end # Protocol