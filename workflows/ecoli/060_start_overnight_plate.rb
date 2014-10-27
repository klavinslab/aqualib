needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the plate ids as a list
      plate_ids: [3798,3797,3799],
      num_colonies: [1,2,3],
      primer_ids: [[2575,2569,2038],[2054,2038],[2575,2569]],
      debug_mode: "Yes"
    }
  end #arguments

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?  
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    plates = io_hash[:plate_ids].collect { |x| find(:item, id: x)[0] }
    num_colonies = io_hash[:num_colonies]
    overnights = []
    colony_plates = []
    sequencing_primer_ids = []
    plates.each_with_index do |p,idx|
      overnights.concat((1..num_colonies[idx]).collect { |n| produce new_sample p.sample.name, of: "Plasmid", as: "TB Overnight of Plasmid" })
      colony_plates.concat((1..num_colonies[idx]).collect { |n| p })
      sequencing_primer_ids.concat((1..num_colonies[idx]).collect { |n| io_hash[:primer_ids][idx] })
    end
    overnight_marker_hash = Hash.new {|h,k| h[k] = [] }
    overnights.each do |x|
      overnight_marker_hash[x.sample.properties["Bacterial Marker"].downcase[0,3]].push x
    end

    overnight_marker_hash.each do |marker, overnight|
      show {
        title "Media preparation in media bay"
        check "Grab #{overnight.length} of 14 mL Test Tube"
        check "Add 3 mL of TB+#{marker[0].upcase}#{marker[1..marker.length]} to each empty 14 mL test tube using serological pipette"
        check "Write down the following ids on cap of each test tube using dot labels #{overnight.collect {|x| x.id}}"
      }
    end

    take plates, interactive: true

    show {
      title "Inoculation"
      note "Use sterile tips to inoculate colonies from plate into 14 mL tubes according to the following table."
      check "Mark each colony on the plate with corresponding overnight id. If the same plate appear more than once in the table, inoculate different isolated coloines on the plate."
      table [["Plate id", "Overnight id"]].concat(colony_plates.collect { |p| p.id }.zip overnights.collect { |o| { content: o.id, check: true } })
    }

    # change location to 37 C shaker incubator

    overnights.each do |o|
      o.location = "37 C shaker incubator"
      o.save
    end
    release overnights, interactive: true
    release plates, interactive: true
    io_hash[:overnight_ids] = overnights.collect { |o| o.id }
    io_hash[:primer_ids] = sequencing_primer_ids
    return { io_hash: io_hash }

  end # main
end # Protocol