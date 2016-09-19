needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

# aiming for a general protocol for making yeast plates for selecting auxotrophic markers

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_selective_plate_types: [11781,11782,11782],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { yeast_selective_plate_types: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    if io_hash[:yeast_selective_plate_types].present?

      plate_hash = Hash.new {|h,k| h[k] = 0 }
      io_hash[:yeast_selective_plate_types].each do |plate_type|
        plate_hash[plate_type] = plate_hash[plate_type] + 1
      end

      plate_tab = [["Plate Type", "Quantity"]]
      plate_hash.each do |plate_type, num|
        sample = find(:sample, id: plate_type)[0].name
        plate_tab.push ["#{sample}", num]
      end

      show {
        title "Make yeast plates"
        note "Make the minimum quality of the following plates."
        table plate_tab
      }

    end

    return { io_hash: io_hash }

  end # main

end # Protocol
