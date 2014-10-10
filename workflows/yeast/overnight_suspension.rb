needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def debug
    false
  end

  def arguments
    {
      #Enter the item id that you are going to start overnight with
      yeast_item_ids: [8437,8431,8426],
      yeast_transformed_strain_ids: [],
      plasmid_ids: [],
      aliquot_numbers: [],
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL YPAD liquid (sterile)",
      #The volume of the overnight suspension to make
      volume: "2",
      debug_mode: "No"
    }
  end

  def main
    io_hash = {yeast_item_ids: [],yeast_overnight_ids: [],plasmid_ids: [],stripwell_ids: [], yeast_transformed_strain_ids: [], yeast_plate_ids: [], yeast_transformation_mixture_ids: [],media_type: "800 mL YPAD liquid (sterile)", volume: "2"}

    io_hash[:yeast_item_ids] = input[:yeast_item_ids]
    io_hash[:aliquot_numbers] = input[:aliquot_numbers]
    io_hash[:yeast_transformed_strain_ids] = input[:yeast_transformed_strain_ids]
    io_hash[:plasmid_ids] = input[:plasmid_ids]
    io_hash[:debug_mode] = input[:debug_mode]

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    yeast_glycerol_stocks = io_hash[:yeast_item_ids].collect {|yid| find(:item, id: yid )[0]}
    yeast_glycerol_stocks.delete_if {|y| y.object_type.name != "Yeast Glycerol Stock"}

    show {
      title "Testing page"
      note(yeast_glycerol_stocks.collect {|x| x.object_type.name})
    }

    yeast_normal_items = io_hash[:yeast_item_ids].collect {|yid| find(:item, id: yid )[0]}
    yeast_normal_items.delete_if {|y| y.object_type.name == "Yeast Glycerol Stock"}

    overnight_glycerol_stocks = yeast_glycerol_stocks.collect{|y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"}

    overnight_normal_items = yeast_normal_items.collect{|y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"}

    overnights = overnight_glycerol_stocks + overnight_normal_items

    overnights.each do |y|
      y.location = "B13.125"
      y.save
    end

    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from glycerol stocks, plates or overnight suspensions"
    }

    # show {
    #   title "Testing page"
    #   note(yeast_glycerol_stocks.collect {|x| x.object_type.name})
    #   note(yeast_normal_items.collect {|x| x.object_type.name})
    #   note(overnight_glycerol_stocks.collect {|x| x.id})
    #   note(overnight_normal_items.collect {|x| x.id})
    # }

  	# tube = choose_object("14 mL Test Tube")
  	# take([tube], interactive: true) {
  	# 	title "Take #{yeast_items.length} tubes"
  	# }

    volume = io_hash[:volume] || 2
    media_type = io_hash[:media_type] || "800 mL YPAD liquid (sterile)"

  	media = choose_object(media_type, take: true)

  	show {
      title "Media preparation in media bay"
      check "Grab #{overnights.length} of 14 mL Test Tube"
  		check "Add #{volume} mL of #{media_type} to each empty 14 mL test tube using serological pipette"
      check "Write down the following ids on cap of each test tube using dot labels #{overnights.collect {|x| x.id}}"
  	}

  	take(yeast_glycerol_stocks, interactive: true, method: "boxes") {
      warning "Work in the M80 area innoculating area while inoculating glycerol stocks to make sure you can put glycerol stocks back into M80 in time."
    } if yeast_glycerol_stocks.length > 0

    yeast_glycerol_stocks.each_with_index do |y,idx|
      show {
        title "Inoculate yeast item #{y.id} into test tube #{overnight_glycerol_stocks[idx].id}"
        bullet "Use a sterile 100 µL tip and vigerously scrape the glycerol stock to get a chunk of stock."
        bullet "Tilt 14 mL tube such that you can reach the media with your tip."
        bullet "Open the tube cap, scrape colony into media, using a swirling motion. Place the tube back on the rack with cap closed."
      }
    end

    release yeast_glycerol_stocks, interactive: true, method: "boxes"

    take yeast_normal_items, interactive: true if yeast_normal_items.length > 0

    yeast_normal_items.each_with_index do |y,idx|
      show {
        title "Inoculate yeast item #{y.id} into test tube #{overnight_normal_items[idx].id}"
        case y.object_type.name
          when "Yeast Overnight Suspension"
            bullet "Pipette 10 µL of culture into tube"
          when "Yeast Plate"
            bullet "Take a sterile 10 µL tip tip, pick up a medium sized colony by gently scraping the tip to the colony."
            bullet "Tilt 14 mL tube such that you can reach the media with your tip."
            bullet "Open the tube cap, scrape colony into media, using a swirling motion. Place the tube back on the rack with cap closed."
        end
      }
    end

#    yeast_normal_items.each_with_index do |y,idx|

    release yeast_normal_items, interactive: true, method: "boxes"

  	release overnights, interactive: true, method: "boxes"
    io_hash[:yeast_overnight_ids] = overnights.collect {|x| x.id}
    
    return {io_hash: io_hash}
  end

end  