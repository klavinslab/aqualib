needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      #Enter the item id that you are going to start overnight with
      yeast_item_ids: [13011],
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL YPAD liquid (sterile)",
      #The volume of the overnight suspension to make
      volume: "2",
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode] || "No"
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    # making sure have the following hash indexes.
    io_hash = io_hash.merge({ yeast_transformed_strain_ids: [], plasmid_stock_ids: [], yeast_parent_strain_ids: [] }) if !input[:io_hash]

    tasks = find(:task,{ task_prototype: { name: "Yeast Transformation" } })
    ready_ids = (tasks.select { |t| t.status == "ready" }).collect { |t| t.id }
    io_hash[:task_ids] = ready_ids

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      io_hash[:yeast_transformed_strain_ids].concat task.simple_spec[:yeast_transformed_strain_ids]
      io_hash[:plasmid_stock_ids].concat task.simple_spec[:yeast_transformed_strain_ids].collect { |yid| find(:sample, id: yid)[0].properties["Plasmid"].in("Plasmid Stock")[0].id }
      io_hash[:yeast_parent_strain_ids].concat task.simple_spec[:yeast_transformed_strain_ids].collect { |yid| find(:sample, id: yid)[0].properties["Parent"].id }
    end

    show {
      note "#{io_hash}"
    }

    io_hash[:media_type] = input[:media_type] || "800 mL YPAD liquid (sterile)"
    io_hash[:volume] = input[:volume] || 2
    io_hash[:large_volume] = 50
    media_type = io_hash[:media_type]
    volume = io_hash[:volume]

    # find all yeast items and related types
    yeast_items = io_hash[:yeast_parent_strain_ids].uniq.collect {|yid| find(:sample, id: yid )[0].in("Yeast Glycerol Stock")[0]}

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
    
    return { io_hash: io_hash }
  end

end  