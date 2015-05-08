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
      io_hash: {},
      #Enter the overnight ids that you are going to start overnight with
      "overnight_ids Yeast Overnight Suspension" => [25980,13576,13577],
      large_volume: 50,
      #Enter the media type you are going to use
      media_type: "800 mL YPAD liquid (sterile)",
      debug_mode: "Yes"
    }
  end  

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", large_volume: 50, yeast_culture_ids: [], media_type: "800 mL YPAD liquid (sterile)" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    yeast_overnights = io_hash[:overnight_ids].collect{ |yid| find(:item, id: yid )[0] }
  	yeast_cultures = []
  	yeast_overnights.each do |y|
  		yeast_culture = produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast 50ml culture"
      yeast_culture.location = "30 C shaker incubator"
      yeast_culture.save
  		yeast_cultures.push yeast_culture
  	end

    if yeast_overnights.length == 0
      show {
        title "No inoculation required"
        note "No inoculation required. Thanks for you effort!"
      }
      return { io_hash: io_hash }
    end
    
    media_type = io_hash[:media_type]
    media = choose_object(media_type, take: true)

    show {
      title "Media preparation"
      warning "Work in the media bay for media prepartion"
      check "Grab #{yeast_overnights.length} of 250 mL Baffled Flask."
      check "Add #{io_hash[:large_volume]} mL of #{media_type} into each 250 mL Baffled Flask."
      check "Label each flask with a piece of tape using following ids:"
      note (yeast_cultures.collect {|x| x.id})
    }

  	take yeast_overnights, interactive: true
    
    innoculation_tab = [["Flask ids","Yeast Overnight ids","Volume (µL)"]]
    yeast_overnights.each_with_index do |y,idx|
      innoculation_tab.push(["#{yeast_cultures[idx].id}",{ content: "#{y.id}", check: true },{ content: "#{io_hash[:large_volume] / 50} mL" }])
    end

    show {
      title "Inoculate yeast overnights into flasks"
      table innoculation_tab
    }
    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"large volume growth")
      end
    end

    delete yeast_overnights

    show {
      title "Discard yeast overnights"
      note "Discard yeast overnights with the following ids. If it is a plastic tube, push down the cap to seal the tube and discard into biohazard box. If it is a glass tube, place it in the dish washing station."
      note yeast_overnights.collect { |y| "#{y}"}
    }

    release yeast_overnights
    release yeast_cultures, interactive: true, method: "boxes"

    io_hash[:yeast_culture_ids] = yeast_cultures.collect {|x| x.id}

    return { io_hash: io_hash }
  end

end  
