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
    io_hash = { debug_mode: "No"}.merge io_hash # set default value of io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    divided_yeast_plates_to_delete = items_beyond_days "Divided Yeast Plate", 75
    yeast_plates_to_delete = items_beyond_days "Yeast Plate", 75
    take divided_yeast_plates_to_delete + yeast_plates_to_delete, interactive: true
    show {
      title "Dispose the old plates you just took"
      check "Dispose in the biohazard box."
    }
    (divided_yeast_plates_to_delete + yeast_plates_to_delete).each do |x|
      x.mark_as_deleted
      x.save
    end
  end

end
