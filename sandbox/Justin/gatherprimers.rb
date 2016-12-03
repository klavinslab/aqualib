needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning
  require 'matrix'

  def arguments
    {
      io_hash: {},
      #Enter the fragment sample ids as array of arrays, eg [[2058,2059],[2060,2061],[2058,2062]]
      primer_ids: [],
      #Tell the system if the ids you entered are sample ids or item ids by enter sample or item, sample is the default option in the protocol.
      sample_or_item: "sample",

      debug_mode: "Yes",
    }
  end
  
  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # setup default values for io_hash.
    io_hash = { primer_ids: [], debug_mode: "No", item_choice_mode: "No" }.merge io_hash

    # Set debug based on debug_mode
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    primer_stocks = io_hash[:primer_ids].collect{ |pid| find(:sample,{id: pid})[0].in("Primer Aliquot")[0] }
   
    take primer_stocks, interactive: true,  method: "boxes"
  end

end
