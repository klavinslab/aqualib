needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      plasmid_stock_ids: [9189,11546,11547,12148,12149,15150,15152,15318,15417,16151,16149],
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { plasmid_stock_ids: [] }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # list of antibiotic plate for yeast selection
    # ClonNat, NatMX, 25 µL, G418, KanMX, 300 µL, Hygromycin, HygMX, 200 µL, Zeocin, BleoMX, 50 µL.
    
    plasmid_marker_hash = Hash.new {|h,k| h[k] = 0 }

    io_hash[:plasmid_stock_ids].each do |pid|
      marker = find(:item, id: pid)[0].sample.properties["Yeast Marker"].downcase[0,3].to_sym
      plasmid_marker_hash.store(marker, plasmid_marker_hash[marker] + 1)
    end

    markers = [ :nat, :kan, :hyg, :ble ]
    antibiotic_hash = { nat: "ClonNat", kan: "G418", hyg: "Hygromycin", ble: "BleoMX" }
    volume_hash = { nat: 25, kan: 300, hyg: 200, ble: 50 }
    make_plate = false  # a variable to indicate whether the user need to make plates

    plasmid_marker_hash.each do |marker, num|

      if markers.include? marker
        show {
          title "Grab YPAD plates and #{antibiotic_hash[marker]} stock"
          check "Grab #{num} YPAD plates."
          check "Grab #{(num * volume_hash[marker] / 1000.0).ceil} 1 mL #{antibiotic_hash[marker]} stock in SF1 or M20."
          check "Waiting for the #{antibiotic_hash[marker]} stock to thaw."
          check "Use sterile beads to spread #{volume_hash[marker]} µL of #{antibiotic_hash[marker]} to each YPAD plates, mark each plate with #{antibiotic_hash[marker]}."
          check "Place the plates with agar side down in the dark fume hood to dry."
        }
        make_plate = true
      end

    end

    if make_plate
      show {
        title "Let plate dry"
        check "Place the plates with agar side down in the dark fume hood to dry."
        note "Noting that placing agar side down is opposite of what you normally do when placing plates in incubator. This will help the antibiotic spread into the agar."
      }
    else
      show {
        title "No antibiotic plate needs to be made."
        note "No antibiotic plate needs to be made. Thanks for your effort."
      }
    end

    return { io_hash: io_hash }

  end # main

end # Protocol