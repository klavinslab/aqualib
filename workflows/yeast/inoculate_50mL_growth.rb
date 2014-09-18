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
      #Enter the overnight ids that you are going to start overnight with
      yeast_overnight_ids: [8437,8431,8426],
      media_type: "YPAD"
    }
  end  

  def main
  	yeast_overnights = []
  	yeast_50mL_cultures = []
  	input[:yeast_overnight_ids].each do |itd|
  		yeast_overnight = find(:item, id: itd)[0]
  		yeast_overnights.push yeast_overnight
  		yeast_50mL_culture = produce new_sample yeast_overnight.sample.name, of: "Yeast Strain", as: "Yeast 50ml culture"
  		yeast_50mL_cultures.push yeast_50mL_culture
  	end

  	show {
  		note(yeast_overnights.collect {|x| x.id})
  	}

  	take yeast_overnights, interactive: true
  	release yeast_50mL_cultures, interactive: true

  end

end  
