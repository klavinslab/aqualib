needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      #Enter the item id that you are going to start overnight with
      item_ids: [28338,28338,28212,28204,28212,28212],
      #media_type could be YPAD or SC or anything you'd like to start with
      media_type: "800 mL YPAD liquid (sterile)",
      #The volume of the overnight suspension to make
      volume: 2,
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?
    io_hash = { debug_mode: "No", item_ids: [], yeast_strain_ids: [], overnight_ids: [], volume: 2, media_type: "800 mL YPAD liquid (sterile)" }.merge io_hash
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    yeast_items = []

    if io_hash[:yeast_strain_ids].length > 0 && io_hash[:item_ids].length == 0

      io_hash[:yeast_strain_ids].each do |yid|
        yeast_strain = find(:sample, id: yid)[0]
        if yeast_strain.in("Yeast Glycerol Stock").length > 0
          if yeast_strain.in("Yeast Glycerol Stock").length == 1
            yeast_items.push yeast_strain.in("Yeast Glycerol Stock")[0]
          elsif yeast_strain.in("Yeast Glycerol Stock").length > 1
            choose_indicator = true
            yeast_strain.in("Yeast Glycerol Stock").each do |y|
              if y.datum[:use_this_for_overnight] == "Yes"
                yeast_items.push y
                choose_indicator = false
              end
            end
            yeast_items.push yeast_strain.in("Yeast Glycerol Stock")[0] if choose_indicator
          end
        elsif yeast_strain.in("Yeast Plate").length > 0
          yeast_items.push yeast_strain.in("Yeast Plate")[0]
        end
      end

    elsif io_hash[:item_ids].length > 0

      yeast_items = io_hash[:item_ids].collect {|yid| find(:item, id: yid )[0]}

    end

    # show {
    #   note "#{io_hash}"
    # }

    if io_hash[:volume] <= 2
      io_hash[:tube_size] = 14
    elsif io_hash[:volume] > 2
      io_hash[:tube_size] = 20
    end

    # group into different types using Hash
    yeast_type_hash = Hash.new {|h,k| h[k] = [] }
    yeast_items.each_with_index do |y,idx|
      yeast_type_hash[y.object_type.name].push y
    end

    # show {
    #   title "Testing page"
    #   note "#{yeast_type_hash}"
    # }

    show {
      title "Protocol information"
      note "This protocol is used to prepare yeast overnight suspensions from glycerol stocks, plates or overnight suspensions for general purposes."
    }

    overnights = []
    
    if yeast_type_hash.empty?
      show {
        title "No overnights need to be prepared"
        note "Thanks for your effort!"
      }
    else
      yeast_type_hash.each do |key,values|
        overnight = values.collect {|v| produce new_sample v.sample.name, of: "Yeast Strain", as: "Yeast Overnight Suspension"}
        overnight.each do |y|
          y.location = "30 C shaker incubator"
          y.save
        end
        overnights.concat overnight

        show {
          title "Media preparation in media bay"
          check "Grab #{overnight.length} of #{io_hash[:tube_size]} mL Test Tube"
          check "Add #{io_hash[:volume]} mL of #{io_hash[:media_type]} to each empty #{io_hash[:tube_size]} mL test tube using serological pipette"
          check "Write down the following ids on the cap of each test tube using dot labels #{overnight.collect {|x| x.id}}"
          check "Go to the M80 area and work there." if key == "Yeast Glycerol Stock"
        }
        take values
        inoculation_tab = [["Item id", "Location", "#{io_hash[:tube_size]} mL tube id", "Colony Selection"]]
        
        # a hash to record how many of the same plate need to be innoculated
        value_num = Hash.new {|h,k| h[k] = 0 }
        value_num_original = Hash.new {|h,k| h[k] = 0 }
        values.each do |v|
          value_num[v] +=1
          value_num_original[v] +=1
        end

        values.each_with_index do |y, idx|
          if y.object_type.name == "Yeast Plate" && y.datum[:correct_colony]
            info = "c#{y.datum[:correct_colony][value_num_original[y] - value_num[y]]}"
            value_num[y] -=1 if y.datum[:correct_colony][value_num_original[y] - value_num[y] + 1]
          else
            info = "NA"
          end
          inoculation_tab.push [ { content: "#{y}", check: true }, y.location, overnight[idx].id, info ]
        end

        show {
          title "Inoculation"
          note "Inoculate yeast into test tube according to the following table. Return items after innocuation."
          case key
          when "Yeast Glycerol Stock"
            bullet "Use a sterile 100 µL tip and vigerously scrape the glycerol stock to get a chunk of stock. Return each glycerol stock immediately after innocuation."
          when "Yeast Overnight Suspension"
            bullet "Pipette 10 µL of culture into tube"
          when "Yeast Plate"
            bullet "Take a sterile 10 µL tip, pick up a medium sized colony by gently scraping the tip to the colony."
          end
          table inoculation_tab
        }
        release values
        release overnight, interactive: true, method: "boxes"
      end
    end

    if io_hash[:task_ids]
      io_hash[:task_ids].each do |tid|
        task = find(:task, id: tid)[0]
        set_task_status(task,"overnight")
      end
    end

    io_hash[:old_overnight_ids]  = io_hash[:overnight_ids]

    io_hash[:overnight_ids] = overnights.collect {|x| x.id}
    
    return { io_hash: io_hash }
  end

end  