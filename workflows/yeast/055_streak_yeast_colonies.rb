# streak yeast plates from colonies
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      yeast_plate_ids: [13578,13579],
      num_colonies: [3,3],
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

    yeast_plates = io_hash[:yeast_plate_ids].collect { |yid| find(:item, id: yid)[0] }
    take yeast_plates, interactive: true
    streaked_yeast_plates = yeast_plates.collect { |y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Plate"}
    num = streaked_yeast_plates.length
    show {
      title "Grab YPAD plates"
      note "Grab #{num} of YPAD plates, label with follow ids"
      note streaked_yeast_plates.collect { |p| "#{p}"}
    }
    tab = [["Yeast plates","New streaked yeast plates","num_colonies"]]
    yeast_plates.each_with_index do |yp,idx|
      tab.push(["#{yp}","#{streaked_yeast_plates[idx]}",{ content: io_hash[:num_colonies][idx], check: true }])
    end
    show {
      title "Streak yeast colonies on new YPAD plates"
      note "Streak using the following table, divide up the plates into num_colonies regions when streaking"
      table tab
    }
    streaked_yeast_plates.each_with_index do |y,idx|
      y.datum = { from: yeast_plates[idx].id, regions: io_hash[:num_colonies][idx] }
      y.location = "30 C incubator"
      y.save
    end
    release yeast_plates, interactive: true
    release streaked_yeast_plates, interactive: true
  end # main
end # Protocol