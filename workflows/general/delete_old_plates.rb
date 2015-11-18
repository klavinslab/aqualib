needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    divided_yeast_plates_to_delete = items_beyond_days "Divided Yeast Plate", 75
    yeast_plates_to_delete = items_beyond_days "Yeast Plate", 75
    show {
      note divided_yeast_plates_to_delete.length
      note yeast_plates_to_delete.length
    }

  end

end
