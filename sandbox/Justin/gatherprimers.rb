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

    # Find fragment stocks into array of arrays
    if io_hash[:item_choice_mode].downcase == "yes"
      primer_stocks = io_hash[:primer_ids].collect{|fids| fids.collect {|fid| choose_sample find(:sample,{id: fid})[0].name, object_type: "Primer Aliquot"}}
    else
      primer_stocks = io_hash[:primer_ids].collect{|fids| fids.collect {|fid| find(:sample,{id: fid})[0].in("Primer Aliquot")[0]}}
    end

    # Rewrite fragment_stocks if the input[:sample_or_item] is specified as item.
    primer_stocks = io_hash[:primer_ids].collect{|fids| fids.collect {|fid| find(:item,{id: fid})[0]}} if input[:sample_or_item] == "item"

    # Flatten the fragment_stocks array of arrays
    primer_stocks_flatten = primer_stocks.flatten.uniq

    take primer_stocks_flatten, interactive: true,  method: "boxes"
  end

end
