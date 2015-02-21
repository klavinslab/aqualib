needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning
  require 'matrix'

  def arguments
    {
      io_hash: {},
      "ids Yeast Plate"=> [15056],
      debug_mode: "Yes"
    }
  end

  def main

    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode] || "No"
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    plates = io_hash[:ids].collect { |x| find(:item, id: x)[0] }
    take plates, interactive: true

    plates.each do |p|
      p.mark_as_deleted
      p.save
    end

    show {
      title "After delete, the items delete status"
      note "#{plates.collect { |p| p.deleted? }}"
    }

    plates.each do |p|
      # p.reload
      # p.store
      p.location = "DFP.4"
    end

    show {
      title "After recover, the items delete status"
      note "#{plates.collect { |p| p.deleted? }}"
    }

  end

end
