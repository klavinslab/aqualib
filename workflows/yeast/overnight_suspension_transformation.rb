# this protocol is for starting overnight suspensions for yeast transformation tasks
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL YPAD liquid (sterile)",
      #The volume of the overnight suspension to make
      volume: "2",
      debug_mode: "Yes",
      group: "cloning"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    # set up io_hash default values
    io_hash = { media_type: "800 mL YPAD liquid (sterile)", volume: 2, group: "technicians", large_volume: 50, yeast_transformed_strain_ids: [], plasmid_stock_ids: [], yeast_parent_strain_ids: [], debug_mode: "No" }.merge io_hash

    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # find how many yeast competent cell aliquots needed for the transformation and decide whether to start overnight or not.
    yeast_parent_strain_num_hash = Hash.new {|h,k| h[k] = 0 }
    io_hash[:yeast_parent_strain_ids].each do |yid|
      yeast_parent_strain_num_hash[yid] += 1
    end
    yeast_strain_need_overnight_ids = []
    yeast_parent_strain_num_hash.each do |yid,num|
      y = find(:sample, id: yid)[0]
      yeast_strain_need_overnight_ids.push yid unless y.in("Yeast Competent Aliquot").length + y.in("Yeast Competent Cell").length >= num
    end

    # find all yeast items and related types, find Yeast Glycerol Stock, if nothing, find Yeast Plate
    yeast_items = []
    yeast_strain_need_overnight_ids.each do |yid|
      if find(:sample, id: yid )[0].in("Yeast Glycerol Stock").length > 0
        yeast_items.push find(:sample, id: yid )[0].in("Yeast Glycerol Stock")[0]
      elsif find(:sample, id: yid )[0].in("Yeast Plate").length > 0
        yeast_items.push find(:sample, id: yid )[0].in("Yeast Plate")[0]
      end
    end

    # group into different types using Hash
    yeast_type_hash = Hash.new {|h,k| h[k] = [] }
    yeast_items.each_with_index do |y,idx|
      yeast_type_hash[y.object_type.name].push y
    end

    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from glycerol stocks, plates or overnight suspensions for yeast transformation tasks."
    }

    if yeast_strain_need_overnight_ids.length == 0
      show {
        title "No overnights need to be prepared"
        note "No overnights need to be prepared, the competent cells needed for the transformation are already in stock. Thanks for you effort!"
      }
    end

    overnights = []

    yeast_type_hash.each do |key,values|
      overnight = values.collect {|v| produce new_sample v.sample.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"}
      move overnight, "30 C shaker incubator"
      overnights.concat overnight
      show {
        title "Media preparation in media bay"
        check "Grab #{overnight.length} of 14 mL Test Tube"
        check "Add #{io_hash[:volume]} mL of #{io_hash[:media_type]} to each empty 14 mL test tube using serological pipette."
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
        table [["Yeast item id","14 mL tube"]].concat(values.collect { |v| "#{v}" }.zip overnight.collect { |o| { content: o.id, check: true } })
      }
      release values, interactive: true, method: "boxes"
      release overnight, interactive: true, method: "boxes"
    end

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"overnight")
      end
    end

    io_hash[:yeast_overnight_ids] = overnights.collect {|x| x.id}
    
    return { io_hash: io_hash }
  end

end  