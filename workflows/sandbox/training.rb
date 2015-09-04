needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      primer_ids: [4360,4344,6089,5979],
      debug_mode: "Yes"
    }
  end

  def main

    # the goal of this protocol is to find any primer stocks that associated with the primer ids and tell users to retrive them from freezer, if none primer stocks can be found, tell the users this info by displaying in the protocol.

    if input[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    primer_ids = input[:primer_ids]
    #
    show {
      note primer_ids
    }
    #
    not_ready_primer_ids = []
    #
    primer_stocks = primer_ids.collect do |id|
      primer_stock = find(:sample, id: id)[0].in("Primer Stock")[0]
      # show {
      #   note primer_stock.id
      #   note primer_stock.location
      # }
      if primer_stock == nil
        not_ready_primer_ids.push id
      end
      primer_stock
    end

    #
    if not_ready_primer_ids.length > 0
      show {
        note "The following primer ids do not have any primer stocks"
        note not_ready_primer_ids.join(", ")
      }
    end
    #
    primer_stocks.compact!
    take primer_stocks, interactive: true, method: "boxes"
    #
    show {
      note primer_stocks.collect { |ps| "#{ps}" }
    }
    #
    release primer_stocks, interactive: true, method: "boxes"

  end

end
