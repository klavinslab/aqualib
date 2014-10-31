needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      #Enter the item id that you are going to start overnight with
      yeast_item_ids: [13011,13010,13022,13023,13024,8437,8431,8426,13022,13023,13024,28703,28702,28701,28700,13012,13013,13014,13015],
      yeast_transformed_strain_ids: [],
      plasmid_ids: [],
      aliquot_numbers: [],
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL YPAD liquid (sterile)",
      #The volume of the overnight suspension to make
      volume: "2",
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = {}
    io_hash[:yeast_item_ids] = input[:yeast_item_ids]
    io_hash[:aliquot_numbers] = input[:aliquot_numbers]
    io_hash[:yeast_transformed_strain_ids] = input[:yeast_transformed_strain_ids]
    io_hash[:plasmid_ids] = input[:plasmid_ids]
    io_hash[:debug_mode] = input[:debug_mode]
    io_hash[:media_type] = input[:media_type] || "800 mL YPAD liquid (sterile)"
    io_hash[:volume] = input[:volume] || 2

    volume = io_hash[:volume]
    media_type = io_hash[:media_type]

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # find all yeast items and related types
    yeast_items = io_hash[:yeast_item_ids].collect {|yid| find(:item, id: yid )[0]}

    # group into different types using Hash
    yeast_type_hash = Hash.new {|h,k| h[k] = [] }
    yeast_items.each_with_index do |y,idx|
      yeast_type_hash[y.object_type.name].push y
    end

    show {
      title "Testing page"
      note "#{yeast_type_hash}"
    }

    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from glycerol stocks, plates or overnight suspensions"
    }

    overnights = []

    yeast_type_hash.each do |key,values|
      overnight = values.collect {|v| produce new_sample v.sample.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"}
      overnight.each do |y|
        y.location = "30 C shaker incubator"
        y.save
      end
      overnights.concat overnight
      show {
        title "Media preparation in media bay"
        check "Grab #{overnight.length} of 14 mL Test Tube"
        check "Add #{volume} mL of #{media_type} to each empty 14 mL test tube using serological pipette"
        check "Write down the following ids on cap of each test tube using dot labels #{overnight.collect {|x| x.id}}"
        check "Go to the M80 area and work there." if key == "Yeast Glycerol Stock"
      }
      take values, interactive: true, method: "boxes"
      show {
        title "Inoculation"
        note "Inoculate yeast into 14 mL tube according to the following table."
        case key
        when "Yeast Glycerol Stock"
          bullet "Use a sterile 100 µL tip and vigerously scrape the glycerol stock to get a chunk of stock."
        when "Yeast Overnight Suspension"
          bullet "Pipette 10 µL of culture into tube" 
        when "Yeast Plate"
          bullet "Take a sterile 10 µL tip, pick up a medium sized colony by gently scraping the tip to the colony."
        end
        table [["Yeast item id","14 mL tube"]].concat(values.collect {|v| v.id}.zip overnight.collect {|o| o.id})
      }
      release values, interactive: true, method: "boxes"
      release overnight, interactive: true, method: "boxes"
    end

    io_hash[:yeast_overnight_ids] = overnights.collect {|x| x.id}
    
    return {io_hash: io_hash}
  end

end  