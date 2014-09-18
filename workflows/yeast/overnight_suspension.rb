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
      yeast_item_ids: [8437,8431,8426],
      media_type: "YPAD"
    }
  end

  def main
  	yeast_items = []
  	overnights = []
  	input[:yeast_item_ids].each do |itd|
  		yeast_item = find(:item, id: itd)
  		yeast_items.push yeast_item
  		# name = yeast_item.sample.name
  		# overnight = produce new_sample name, of: "Yeast Strain", as: "Yeast Overnight Suspension"
  		# overnights.push overnight
  	end

  	show {
  		note (yeast_items.collect {|x| x.id}
  	}

  	# take yeast_items, interactive: true
  	# release overnights, interactive: true

  end

end  