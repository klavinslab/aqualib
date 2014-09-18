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
      item_ids: [8437,8431,8426],
      media_type: "YPAD"
    }
  end

  def main
  	items = []
  	overnights = []
  	item_ids.each do |id|
  		item = find(item, id: id)
  		items.push item if item
  		overnight = produce new_sample item.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"
  		overnights.push overnight
  	end

  	take items, interactive: true

  end

end  