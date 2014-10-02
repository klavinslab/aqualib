needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def debug
    true
  end

  def arguments
    {
      #Enter the item id that you are going to start overnight with
      yeast_item_ids: [8437,8431,8426,27629],
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "50 mL YPAD liquid aliquot (sterile)",
      #The volume of the overnight suspension to make
      volume: "2"
    }
  end

  def main
    yeast_glycerol_stocks = input[:yeast_item_ids].collect {|yid| find(:item, id: yid )[0]}
    yeast_glycerol_stocks.delete_if {|y| y.object_type.name != "Yeast Glycerol Stock"}

    yeast_normal_items = input[:yeast_item_ids].collect {|yid| find(:item, id: yid )[0]}
    yeast_normal_items.delete_if {|y| y.object_type.name == "Yeast Glycerol Stock"}

    overnight_glycerol_stocks = yeast_glycerol_stocks.collect{|y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"}

    overnight_normal_items = yeast_normal_items.collect{|y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"}

    overnights = overnight_glycerol_stocks + overnight_normal_items

    show {
      title "Testing page"
      note(yeast_glycerol_stocks.collect {|x| x.object_type.name})
      note(yeast_normal_items.collect {|x| x.object_type.name})
      note(overnight_glycerol_stocks.collect {|x| x.id})
      note(overnight_normal_items.collect {|x| x.id})
    }

  	# tube = choose_object("14 mL Test Tube")
  	# take([tube], interactive: true) {
  	# 	title "Take #{yeast_items.length} tubes"
  	# }

    volume = input[:volume]
    media_type = input[:media_type]

  	media = choose_object(media_type, take: true)

  	show {
      title "Media preparation"
      check "Grab #{overnights.length} of 14 mL Test Tube"
  		check "Add #{volume} mL of #{media_type} to each empty 14 mL test tube"
      check "Write down the following ids on cap of each test tube using dot labels #{overnights.collect {|x| x.id}}"
  	}

  	take yeast_glycerol_stocks, interactive: true, method: "boxes"

    yeast_glycerol_stocks.each_with_index do |y,idx|
      show {
        title "Inoculate yeast item #{y.id} into test tube #{overnight_glycerol_stocks[idx].id}"
        bullet "Use a sterile 100 µL tip and vigerously scrape the glycerol stock to get a chunk of stock."
        bullet "Tilt 14 mL tube such that you can reach the media with your tip."
        bullet "Open the tube cap, scrape colony into media, using a swirling motion. Place the tube back on the rack with cap closed."
      }
    end

    take yeast_normal_items, interactive: true

    yeast_normal_items.each_with_index do |y,idx|
      show {
        title "Inoculate yeast item #{y.id} into test tube #{overnight_glycerol_stocks[idx].id}"
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

  	return input.merge yeast_overnight_ids: overnights.collect {|x| x.id}

  end

end  