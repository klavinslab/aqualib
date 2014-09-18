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
  	input[:item_ids].each do |itd|
  		item = find(:item, id: itd)
  		items.push item
  		# name = item.sample.name
  		# overnight = produce new_sample name, of: "Yeast Strain", as: "Yeast Overnight Suspension"
  		# overnights.push overnight
  	end

  	take items, interactive: true
  	# release overnights, interactive: true

  end

end  