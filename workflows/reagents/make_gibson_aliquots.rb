needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#the above lines include the libraries from outside

class Protocol

  #the following lines make the libraries available to the class
  include Standard
  include Cloning

  def sort_by_location fragments
    location_prefix = fragments[0].location.split(".")[0]
    location_arrays = fragments.map { |frag| frag.location[4..-1].split(".") }
    sorted_locations = location_arrays.sort { |row1, row2| 
                                              comp = row1[0].to_i <=> row2[0].to_i
                                              comp = comp.zero? ? row1[1].to_i <=> row2[1].to_i : comp
                                              comp.zero? ? row1[2].to_i <=> row2[2].to_i : comp }
    location_strings = sorted_locations.map { |row| "#{location_prefix}.#{row[0]}.#{row[1]}.#{row[2]}" }
    fragments.sort_by! { |frag| location_strings.index(frag.location) }
  end # sort_by_location

  def group_by_box stocks
    grouped_stocks_hash = Hash.new()
    stocks.each { |stock|
      box = stock.location[4..-1].split(".")[1]
      if grouped_stocks_hash[box]
        grouped_stocks_hash[box].push(stock)
      else
        grouped_stocks_hash[box] = Array.new(1) { stock }
      end
    }
    grouped_stocks_hash.values
  end # group_by_box

  def group_by_sample_name stocks
    grouped_stocks_hash = Hash.new()
    stocks.each { |stock|
      s_name = stock.sample.name
      if grouped_stocks_hash[s_name]
        grouped_stocks_hash[s_name].push(stock)
      else
        grouped_stocks_hash[s_name] = Array.new(1) { stock }
      end
    }
    grouped_stocks_hash.values
  end # group_by_sample_name

  def find_replacement_stock stock, not_enough_volume_stocks
    i = 1
    replacement = stock.sample.in("#{stock.object_type.name}")[i]
    while (not_enough_volume_stocks.include? replacement)
      i += 1
      replacement = stock.sample.in("#{stock.object_type.name}")[i]
    end
    replacement
  end # find_replacement_stock

  def fill_array rows, cols, num, val
    num = 0 if num < 0
    array = Array.new(rows) { Array.new(cols) { -1 } }
    (0...num).each { |i|
      row = (i / cols).floor
      col = i % cols
      array[row][col] = val
    }
    array
  end # fill_array

  def arguments
    {
      debug_mode: "no"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    #this ensures that debug mode works
    if input[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    inventory_hash = {
      "5X ISO Buffer" => "Enzyme Buffer Stock",
      "T5 exonuclease" => "Enzyme Stock",
      "Phusion Polymerase" => "Enzyme Stock",
      "Taq DNA Ligase" => "Enzyme Stock"
    }
    sample_volumes = {
      "5X ISO Buffer" => 320,
      "T5 exonuclease" => 0.64,
      "Phusion Polymerase" => 20,
      "Taq DNA Ligase" => 160,
      "MG H2O" => 700
    }

    enzyme_stocks = inventory_hash.collect { |sample_name, container_name| find(:sample, name: sample_name)[0].in(container_name)[0] }
    messages = []
    enzyme_stocks.each do |stock|
      if stock == nil
        messages.push "#{stock.sample.name} does not have a #{stock.object_type.name}"
      end
    end

    if messages.any?
      show {
        title "Some stock is empty!"
        messages.each do |message|
          note message
        end
      }
      return
    end

    #takes inputs from arguments
    #iso_buffer = input[:iso_buffer]
    t5 = input[:t5]
    phusion_pol = input[:phusion_pol]
    ligase = input[:ligase]

    show {
      title "Make Gibson Aliquots Information"
      note "This protocol makes 80 gibson aliquots. Make sure you keep all associated enzymes ON ICE whilst preparing the master mix."
    }

    #checks to find stocks of all enzymes and buffers. Returns an error if stock isn't present
    #iso_stock = find(:sample, id: iso_buffer)[0].in("Enzyme Buffer Stock")[0]
    #iso_stock = find(:item, sample: { object_type: { name: "Enzyme Buffer" }, sample: { name: "5X ISO Buffer" } } )

    show {
      title "Grab 80 small sample tubes"
      check "Grab ice block with a 96-well aluminum tube rack."
      check "Grab 80 small sample tubes, and arrange them on the aluminum tube rack."
      check "Place ice block with arranged tubes in a small freezer."
    }

    show {
      title "Obtain sample cooling block"
      check "Grab a sample cooling block from the M20 freezer."
      warning "All enzymes will go in this sample cooling block."
    }

    #if stock is found, then interatively shows where to take stocks from
    sort_by_location enzyme_stocks
    (group_by_box enzyme_stocks).each { |stocks|
      take stocks, interactive: true,  method: "boxes"
    }
    not_enough_volume_stocks = []
    replacement_stocks = []
    no_replacement = false
    while true
      enough_volume = show {
        title "Check if enzyme stocks have enough volume for master mix"
        enzyme_stocks.sort_by { |stock| inventory_hash.keys.index(stock.sample.name) }.each { |stock|
          additional_stocks = not_enough_volume_stocks.select { |nev_stock| nev_stock.sample.name == stock.sample.name }.map!{ |nev_stock| "#{nev_stock}" }
          if additional_stocks.any?
            select ["Yes", "No"], var: "c#{stock.id}", label: "Do #{(additional_stocks + ["#{stock}"]).join(" + ")} (#{stock.sample.name}) together have at least #{sample_volumes[stock.sample.name]} µL?", default: "Yes"
          else
            select ["Yes", "No"], var: "c#{stock.id}", label: "Does #{stock} (#{stock.sample.name}) have at least #{sample_volumes[stock.sample.name]} µL?", default: "Yes"
          end
        }
      }
      if enough_volume.has_value? "No"
        enzyme_stocks.each { |stock|
          if enough_volume[:"c#{stock.id}".to_sym] == "No"
            not_enough_volume_stocks.push stock
            replacement = find_replacement_stock stock, not_enough_volume_stocks
            if replacement
              replacement_stocks.push replacement
              enzyme_stocks.push replacement
            else
              no_replacement = true
            end
          end
        }
        break if no_replacement
        not_enough_volume_stocks.each { |stock| enzyme_stocks.delete stock }
        new_enzyme_stocks = enzyme_stocks - Job.find(jid).touches.map { |t| t.item }
        take new_enzyme_stocks, interactive: true
        sort_by_location enzyme_stocks
      else
        break
      end
    end
    
    if no_replacement
      # Protocol cannot finish because one or more stocks are unavailable
      show {
        title "Gibson aliquots cannot be prepared"
        note "Unfortunately, there are not enough available enzymes to complete this protocol."
      }
      (group_by_box Job.find(jid).touches.map { |t| t.item }).each { |item|
        release item, interactive: true,  method: "boxes"
      }
      return
    end

    if not_enough_volume_stocks.any?
      not_enough_volume_stocks.sort_by! { |stock| inventory_hash.keys.index(stock.sample.name) }
      additional_stocks_grouped = group_by_sample_name not_enough_volume_stocks
      show {
        title "Consolidate enzyme stocks"
        additional_stocks_grouped.each { |additional_stocks|
          stocks_to_consolidate = additional_stocks.map { |stock| "#{stock}" }.join(" + ")
          stock_to_keep = enzyme_stocks.find { |stock| stock.sample.name == additional_stocks[0].sample.name }
          check "Pipette the contents of #{stocks_to_consolidate} into #{"#{stock_to_keep}"} (#{stock_to_keep.sample.name}), and discard #{stocks_to_consolidate}."
        }
      }
      delete not_enough_volume_stocks
    end

    show {
      title "Grab Eppendorf tube"
      check "Grab a new 1.5 ml Eppendorf tube and place it into the sample ice block."
    }

    show {
      title "Prepare Gibson master mix"
      check "Pipette the following stocks into the Eppendorf tube."
      table [["Stock", "Volume (µL)"]]
             .concat(enzyme_stocks.sort_by { |stock| inventory_hash.keys.index(stock.sample.name) }.collect { |stock| ["#{stock} (#{stock.sample.name})", { check: true, content: sample_volumes[stock.sample.name] }] })
             .concat([["MG H2O", { check: true, content: sample_volumes["MG H2O"] }]])
      check "Gently vortex the Eppendorf tube until contents are well mixed."
    }

    #release stocks interactively once the protocol is finished
    (group_by_box enzyme_stocks).each { |stocks|
      release stocks, interactive: true,  method: "boxes"
    }

    show {
      title "Pipette out aliquots"
      check "Grab the pre-prepared tubes back out of the small freezer."
      check "Aliquot 15 µL of the Eppendorf tube contents into each of the 80 small sample tubes."
    }

    aliquot_batch = produce new_collection "Gibson Aliquot Batch", 10, 10

    used_batch_colors = find(:item, object_type: { name: "Gibson Aliquot Batch" }).sort { |batch1, batch2| batch1.id <=> batch2.id }
                                                                                  .select { |batch| batch.datum[:label_color] != "" }
                                                                                  .map { |batch| batch.datum[:label_color] }
                                                                                  .compact
    batch_data = show {
      title "Finish preparing the Gibson aliquot batch"
      get "number", var: "num_aliquots", label: "Enter the number of aliquots you were able to prepare.", default: 80
      note "Of the existing Gibson aliquot batches, the following colors have already been used: #{used_batch_colors.join(", ")}." if used_batch_colors.any?
      get "text", var: "color", label: "Enter the color with which you have chosen to label this batch.", default: ""
      check "Grab a freezer box with a 10x10 divider."
      check "Label the box with #{aliquot_batch}, color, your initials, and today's date."
    }
    batch_matrix = fill_array 10, 10, batch_data[:num_aliquots], find(:sample, name: "Gibson Aliquot")[0].id
    aliquot_batch.matrix = batch_matrix
    aliquot_batch.datum = aliquot_batch.datum.merge({ from: enzyme_stocks.collect { |s| s.id }, label_color: batch_data[:color], tested: "No" })
    aliquot_batch.location = "M20 freezer"
    aliquot_batch.save

    show {
      title "Place Gibson aliquot batch in fridge"
      check "Please put the sample tubes in the freezer box."
      check "Return the cooling block and the labeled freezer box to the M20 freezer."
    }

    release [aliquot_batch]
    io_hash[:gibson_aliquot_batch] = aliquot_batch.id

    test_gibson_plasmid = find(:sample, name: "Test_gibson")[0]
    test_gibson_fragments = [find(:sample, name: "fYG13")[0], find(:sample, name: "fYG7")[0], find(:sample, name: "fYG8")[0], find(:sample, name: "PS-yeGFP-TP")[0]]
    tp = TaskPrototype.where("name = 'Gibson Assembly'")[0]
    t = Task.new(name: "Test_Gibson_#{aliquot_batch.id}", 
                specification: { "plasmid Plasmid" => test_gibson_plasmid.id, "fragments Fragment" => test_gibson_fragments.map { |frag| frag.id } }.to_json, 
                task_prototype_id: tp.id, 
                status: "waiting", 
                user_id: Job.find(jid).user_id)
    t.save
    t.notify "Automatically created from Make Gibson Aliquots.", job_id: jid
    io_hash[:test_gibson_task_id] = t.id

    return { io_hash: io_hash }
  end
end