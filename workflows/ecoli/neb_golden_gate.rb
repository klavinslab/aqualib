needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol

  include Cloning
  include Standard
  
  def arguments
    {
      io_hash: {},
      plasmid_ids: [11948, 11935],
      backbone_ids: [13832, 13887],
      inserts_ids: [[13832, 13911],[13792, 13918, 13919]],
      restriction_enzyme_ids: [13938, 13938],
      task_ids: [40213],
      debug_mode: "No",
    }
  end

  def main
    total_volume = 10.0
    enzyme_volume = 0.5
    buffer_volume = total_volume * 0.1
    
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # setup default values for io_hash.
    io_hash = { plasmid_ids: [], backbone_ids: [], inserts_ids: [[]], restriction_enzyme_ids: [], task_ids: [], debug_mode: "No" }.merge io_hash

    # set debug based on debug_mode
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    # check for length in backbone and inserts (error out if none)
    missing_length_task_ids = io_hash[:task_ids].select do |tid|
      task = find(:task, id: tid)[0]
      spec = task.simple_spec

      ([spec[:backbone]] + spec[:inserts]).any? do |sid|
        sample = find(:sample, id: sid)[0]

        if sample.properties["Length"] == 0
          task.notify "#{sample.name} has an invalid length of 0. Please enter a valid length!"
          true
        else
          false
        end
      end
    end

    # create hash for storing data related to tasks (built more later)
    task_hashes = (io_hash[:task_ids] - missing_length_task_ids).map do |tid|
      task = find(:task, id: tid)[0]
      spec = task.simple_spec

      { task: task,
        plasmid_id: spec[:plasmid],
        backbone_id: spec[:backbone],
        inserts_ids: spec[:inserts],
        enzyme: find(:sample, id: spec[:restriction_enzyme])[0].in("Enzyme Stock")[0],
        sample_ids: [spec[:backbone]] + spec[:inserts],
        stocks: Array.new(1 + spec[:inserts].length) { nil },
        stocks_to_dilute: Array.new(1 + spec[:inserts].length) { nil } }
    end

    # look for 40 fmole/uL stocks for backbone and inserts
    task_hashes.each do |task_hash|
      ([task_hash[:backbone_id]] + task_hash[:inserts_ids]).each_with_index do |sid, idx|
        sample = find(:sample, id: sid)[0]
        stock = sample.in("40 fmole/µL #{sample.sample_type.name} Stock")[0]

        if stock.nil?
          task_hash[:stocks_to_dilute][idx] = sample.in("#{sample.sample_type.name} Stock")[0]
          puts "No 40 fmole/uL stock found for #{sample.sample_type.name}!"
          puts "  Found #{sample.in("#{sample.sample_type.name} Stock")[0].id} instead"
        else
          task_hash[:stocks][idx] = stock
          puts "40 fmole/uL stock found for #{sample.sample_type.name}!"
        end
      end
    end

    # take all items needed from inventory
    enzyme = find(:sample, name: "NEB Golden Gate Assembly Mix (BsaI)")[0].in("Enzyme Stock")[0]
    enzyme_buffer = find(:sample, name: "NEB Golden Gate Buffer")[0].in("Enzyme Stock")[0]
    take task_hashes.map { |th| th[:stocks].compact + th[:stocks_to_dilute].compact }.flatten.uniq + [enzyme, enzyme_buffer], interactive: true, method: "boxes"

    # save stocks_to_dilute concentrations
    ensure_stock_concentration task_hashes.map { |th| th[:stocks_to_dilute].compact }.flatten.uniq
    task_hashes.each do |task_hash|
      task_hash[:stocks_to_dilute].compact.each do |stock|
        stock.datum = stock.datum.merge({ fmole_ul: stock.datum[:concentration] / (stock.sample.properties["Length"] * 66 / 1e5) })
        stock.save
      end

      puts "#{task_hash[:stocks_to_dilute].compact.map { |stock| stock.datum[:fmole_ul] }} fmole/uL"
    end

    task_hashes.each { |th| puts "stocks #{th[:stocks]}, stocks_to_dilute #{th[:stocks_to_dilute]}" }

    # if stocks too concentrated (< 0.2 uL to pipette into reaction), dilute to 40 fmole/uL and make new item
    stocks_to_dilute = task_hashes.map { |th| th[:stocks_to_dilute].compact.select { |stock| 40.0 / stock.datum[:fmole_ul] < 0.2 } }.flatten.uniq
    if stocks_to_dilute.any?

      # produce 40 fmole/µL stocks
      diluted_stocks = []
      task_hashes.each do |task_hash|
        task_hash[:stocks].map!.with_index do |stock, idx|
          stock_to_dilute = task_hash[:stocks_to_dilute][idx]
          if stocks_to_dilute.include? stock_to_dilute
            diluted_stock = stock_to_dilute.sample.in("40 fmole/µL #{stock_to_dilute.sample.sample_type.name} Stock")[0]
            if diluted_stock.nil?
              diluted_stock = produce new_sample stock_to_dilute.sample.name, 
                                of: stock_to_dilute.sample.sample_type.name, 
                                as: "40 fmole/µL #{stock_to_dilute.sample.sample_type.name} Stock"
            end
            
            diluted_stocks.push diluted_stock unless diluted_stocks.include? diluted_stock

            diluted_stock
          else
            stock
          end
        end
      end

      # dilute to 40 fmole/µL from stock
      water_volumes = stocks_to_dilute.map { |s| (s.datum[:fmole_ul] / 40.0 - 1.0).round(1) }

      dilution_table = [["Newly labeled tube", "Water volume", "Template stock, 1 µL"]]
      stocks_to_dilute.each_with_index do |s, idx|
        dilution_table.push [diluted_stocks[idx].id, { content: water_volumes[idx].to_s + " µL", check: true }, { content: s.id, check: true }]
      end

      show do
        title "Make 40 fmole/µL Stocks"

        check "Grab #{stocks_to_dilute.length} 1.5 mL tubes, label them with #{diluted_stocks.join(", ")}."
        check "Add water and stocks into newly labeled 1.5 mL tubes following the table below."

        table dilution_table

        check "Vortex and then spin down for a few seconds."
      end
    end

    # if stocks not concentrated enough, add to task_hash[:stocks]
    puts "stocks " + task_hashes.map { |th| th[:stocks].map { |s| s.nil? ? nil : s.id } }.to_s
    puts "stocks_to_dilute " + task_hashes.map { |th| th[:stocks_to_dilute].map { |s| s.nil? ? nil : s.id } }.to_s
    task_hashes.each { |task_hash| task_hash[:stocks].map!.with_index { |stock, idx| stock.nil? ? task_hash[:stocks_to_dilute][idx] : stock } }
    puts "stocks " + task_hashes.map { |th| th[:stocks].map { |s| s.nil? ? nil : s.id } }.to_s
    puts "stocks_to_dilute " + task_hashes.map { |th| th[:stocks_to_dilute].map { |s| s.nil? ? nil : s.id } }.to_s

    # If any stocks too dilute, calculate volume needed to achieve 40 fmole/uL
    task_hashes.each do |task_hash|
      task_hash[:volumes] = task_hash[:stocks].map.with_index do |stock, index|
        conc = stock.datum[:fmole_ul]
        v = 0
        if stock.object_type.name.include? "40 fmole/µL"
          v = enzyme_volume
        else
          v = (40.0 / conc).round(1)
        end
        
        # Use half as much if its the backbone
        if index == 0
          v = v * 0.5
        end
        v
      end

      total_stock_vol = task_hash[:volumes].inject(0) { |sum, v| sum + v }
      task_hash[:water_vol] = [total_volume - enzyme_volume - total_stock_vol, 0].max
    end

    # TODO volume checks. Ensure there is enough volume in each stock

    # make stripwell, one well per reaction. TODO support multiple stripwells
    puts task_hashes.map { |th| find(:sample, id: th[:plasmid_id])[0] }
    stripwell = (produce spread task_hashes.map { |th| find(:sample, id: th[:plasmid_id])[0] }, "Stripwell", 1, 12)[0]

    
    # dispense H20 to total_volume uL
    water_table = [["Well", "Water (µL)"]]
    task_hashes.each_with_index do |task_hash, idx|
      water_table.push [idx + 1, { content: task_hash[:water_vol], check: true }]
    end

    show do
      title "Dispense water"

      note "Pipette water into the stripwell according to the following table:"

      table water_table
    end

    show do
      title "Prepare stripwells"

      note "Label a #{task_hashes.length <= 6 ? 6 : 12}-well stripwell #{stripwell}."
    end

    # dispense buffer
    show do
      title "Dispense NEB Golden Gate Buffer"
      buffer_table = [["Well", "NEB GG Buffer, #{buffer_volume} μL"]]
      note "Item ID: #{enzyme_buffer.id}"
      task_hashes.each_with_index do |task_hash, idx|
        buffer_table.push [{ content: idx+1, check: true }, enzyme_buffer.id]
      end
      table buffer_table
    end

    # dispense 1 uL enzyme into stripwell
    show do
      title "Dispense NEB Golden Gate Mix"
      enzyme_table = [["Well", "NEB GG Mix, #{enzyme_volume} µL"]]
      note "Item ID: #{enzyme.id}"
      task_hashes.each_with_index do |task_hash, idx|
        enzyme_table.push [{content: idx + 1, check: true}, enzyme.id]
      end
      table enzyme_table
    end


    # dispense DNA
    task_hashes.each_with_index do |task_hash, sw_idx|
      stock_table = [["Stock Id", "Volume (µL)"]]
      task_hash[:stocks].each_with_index do |stock, idx|
        stock_table.push [stock.id, { content: task_hash[:volumes][idx], check: true }]
      end

      show do
        title "Dispense DNA (well #{sw_idx + 1})"

        note "Pipette DNA into the #{(sw_idx + 1).ordinalize} well of the stripwell according to the following table:"

        table stock_table
      end
    end

    # TODO spin down and put in thermocycler (37 C 1', 16 C 1') x 30, 55 C 5'
    therm = show do
      title "Start thermocycler"

      check "Place the stripwell into an available thermocycler and close the lid."
      check "Run the following thermocycler protocol. Choose 10ul as the volume and click OK"
      note "  Step 1: 37C, 1 min"
      note "  Step 2: 16C, 1 min"
      note "  Step 3: GOTO 1 X 30"
      note "  Step 4: 55C 5 min"
      get "text", var: "name", label: "Enter the name of the thermocycler used", default: "TC3"
      
      # TODO populate show block with proper instructions
      # check "Click 'Home' then click 'Saved Protocol'. Choose 'YY' and then 'CLONEPCR'."
      # check "Set the anneal temperature to . This is the 3rd temperature."

      # check "Set the 4th time (extension time) to be ."
      # check "Press 'Run' and select 50 µL."
    end
    stripwell.location = therm[:name]
    stripwell.save

    release task_hashes.map { |th| th[:stocks].compact + th[:stocks_to_dilute].compact }.flatten.uniq + [enzyme, enzyme_buffer], interactive: true, method: "boxes"
    release [stripwell]

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task, "golden gate")
    end

    io_hash[:golden_gate_result_stripwell_id] = stripwell.id

    return { io_hash: io_hash }
  end

end
