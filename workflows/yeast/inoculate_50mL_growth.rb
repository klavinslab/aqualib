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
      io_hash: {}
      #Enter the overnight ids that you are going to start overnight with
      yeast_overnight_ids: [8437,8431,8426],
      #Enter the media type you are going to use
      media_type: "800 mL YPAD liquid (sterile)"
    }
  end  

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?
  	yeast_overnights = io_hash[:yeast_overnight_ids].collect{|yid| find(:item, id: yid )[0]}
    # show {
    #   note(yeast_overnights.collect {|x| x.id})
    # }
  	yeast_50mL_cultures = []
  	yeast_overnights.each do |y|
  		yeast_50mL_culture = produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast 50ml culture"
      yeast_50mL_culture.location = "B13.125"
      yeast_50mL_culture.save
  		yeast_50mL_cultures.push yeast_50mL_culture
  	end

    media_type = io_hash[:media_type]
    media = choose_object(media_type, take: true)

    show {
      title "Media preparation"
      check "Grab #{yeast_overnights.length} of 250 mL Baffled Flask"
      check "Add 50 mL of #{media_type} into each 250 mL Baffled Flask"
      check "Label each flask with a piece of tape using following ids"
      note (yeast_50mL_cultures.collect {|x| x.id})
      warning "Work in the media bay for media prepartion"
    }

  	take yeast_overnights, interactive: true
    
    tab = [["Flask ids","Yeast Overnight ids","Volume (µL)"]]
    yeast_overnights.each_with_index do |y,idx|
      tab.push(["#{yeast_50mL_cultures[idx].id}","#{y.id}",{ content: "1 mL", check: true }])
    end
    show {
      title "Inoculate yeast overnights into flasks"
      table tab
    }

    release yeast_overnights, interactive: true, method: "boxes"
  	release yeast_50mL_cultures, interactive: true, method: "boxes"
    io_hash[:yeast_culture_ids] = yeast_50mL_cultures.collect {|x| x.id}  
    return {io_hash: io_hash}
  end

end  
