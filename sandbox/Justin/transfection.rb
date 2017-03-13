needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the plasmid  ids as array of arrays, eg [[2058,2059],[2060,2061],[2058,2062]]
      Plasmids: [[1],[2]],
      #Tell the system if the ids you entered are sample ids or item ids by enter sample or item, sample is the default option in the protocol.
      sample_or_item: "sample",
      debug_mode: "Yes"
    }
  end


  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    
     # setup default values for io_hash.
    io_hash = { Plasmids: [[]], debug_mode: "No" }.merge io_hash
    
    io_hash[:plasmid_ids] = io_hash[:Plasmids]
    
    
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    
    err_messages = []

    plasmid_stocks = io_hash[:plasmid_ids].collect { |ids|
      ids.collect { |id|
        err_messages.push "Sample #{id} does not have any stock" if !find(:sample,{ id: id })[0].in("Plasmid Stock")[0]
        find(:sample,{ id: id })[0].in("Plasmid Stock")[0]
      }
    }
    
    uniq_plasmid_stocks = plasmid_stocks.flatten.uniq
    
    show {
      title "CHO Transfection"
      note "This protocol will perform a co-transfection of CHO-K1 cells using Viafect with the following plasmids."
      note io_hash[:Plasmids].collect { |id| "#{id}" }
      }
    
    stocks = uniq_plasmid_stocks;
    
    take stocks, interactive: true, method: "boxes"

# Set tasks in the io_hash to be transfected
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"transfected")
      end
    end
    return { io_hash: io_hash }

  end
end
