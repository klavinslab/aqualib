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
      media_type: "YPAD",
      volume: "2"
    }
  end

  def main
  	yeast_items = []
  	overnights = []
  	volume = input[:volume]
  	input[:yeast_item_ids].each do |itd|
  		yeast_item = find(:item, id: itd)[0]
  		yeast_items.push yeast_item
  		name = yeast_item.sample.name
  		overnight = produce new_sample name, of: "Yeast Strain", as: "Yeast Overnight Suspension"
  		overnights.push overnight
  	end

  	tube = choose_object("14 mL Test Tube")
  	take([tube], interactive: true) {
  		title "Take #{yeast_items.length} tubes"
  	}

  	show {
  		note(yeast_items.collect {|x| x.id})
  		note(tube.id)
  	}

  	show {
  		note "Add #{volume} µL of to each empty 14 mL test tube"
  	}



  	take yeast_items, interactive: true, method: "boxes"
  	release overnights, interactive: true, method: "boxes"

  	return input.merge yeast_overnight_ids: overnights.collect {|x| x.id}

  end

end  