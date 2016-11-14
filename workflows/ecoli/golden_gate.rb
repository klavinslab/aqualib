needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol

  include Cloning
  include Standard

  def arguments
    {
      io_hash: {},
      backbone_ids: [13832, 13887],
      inserts_ids: [[13832, 13911],[13792, 13918, 13919]],
      restriction_enzyme_ids: [13938, 13938],
      debug_mode: "No",
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if !input[:io_hash] || input[:io_hash].empty?

    # setup default values for io_hash.
    io_hash = { backbone_ids: [], inserts_ids: [[]], restriction_enzyme_ids: [], task_ids: [], debug_mode: "No" }.merge io_hash

    # Set debug based on debug_mode
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end

    show {
      note io_hash.to_s
    }

    # TODO check for length in backbone and inserts (error out if none)
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

    show do
      note missing_length_task_ids
    end

    # create hash for storing data related to tasks (built more later)
    task_hashes = (io_hash[:task_ids] - missing_length_task_ids).map do |tid|
      task = find(:task, id: tid)[0]
      spec = task.simple_spec

      { task: task,
        backbone_id: spec[:backbone],
        inserts_ids: spec[:inserts],
        enzyme: find(:sample, id: spec[:restriction_enzyme])[0].in("Enzyme Stock")[0],
        sample_ids: [spec[:backbone]] + spec[:inserts],
        stocks: Array.new(spec[:backbone].length + spec[:inserts].length) { nil } },
        stocks_to_dilute: Array.new(spec[:backbone].length + spec[:inserts].length) { nil } }
    end

    # TODO look for 40 fmole/uL stocks for backbone and inserts
    task_hashes.each do |task_hash|
      ([task_hash[:backbone_id]] + task_hash[:inserts_ids]).each_with_index do |sid, idx|
        sample = find(:sample, id: sid)[0]
        stock = sample.in("40 fmole/µL #{sample.sample_type.name} Stock")[0]

        if stock.nil?
          task_hash[:stocks_to_dilute][idx] = sample.in("#{sample.sample_type.name} Stock")[0]
        else
          task_hash[:stocks][idx] = stock
        end
      end
    end

    take task_hashes.map { |th| th[:stocks].compact + th[:stocks_to_dilute].compact + [th[:enzyme]] }.flatten.uniq

    # TODO if no 40 fmole/uL, determine concentration of stocks
    ensure_stock_concentration task_hashes.map { |th| th[:stocks_to_dilute].compact }.flatten.uniq
    

    # TODO If stocks too concentrated, dilute to 40 fmole/uL and make new item
    # produce 1 ng/µL Plasmid Stocks
    diluted_stocks = []
    task_hashes.each do |task_hash|
      task_hash[:stocks].map! do |stock|
        next unless stock.nil?
        diluted_stock = produce new_sample stock.sample.name, of: stock.sample.sample_type.name, as: ("1 fmole/µL " + s.sample.sample_type.name + " Stock") 
        diluted_stocks.push diluted_stock

        diluted_stock
    end

    # collect all concentrations
    stocks_to_dilute = task_hashes.map { |th| th[:stocks_to_dilute].compact }.flatten
    concs = stocks_to_dilute.map { |s| s.datum[:concentration].to_f }
    water_volumes = concs.collect { |c| c - 1.0 }

    # build a checkable table for user
    dilution_table = [["Newly labled tube", "Template stock, 1 µL", "Water volume"]]
    stocks_to_dilute.each_with_index do |s, idx|
      dilution_table.push([diluted_stocks[idx].id, { content: s.id, check: true }, { content: water_volumes[idx].to_s + " µL", check: true }])
    end

    # display the dilution info to user
    show {
      title "Make 40 fmole/µL Stocks"
      check "Grab #{stocks_to_dilute.length} 1.5 mL tubes, label them with #{diluted_stocks.join(", ")}"
      check "Add stocks and water into newly labeled 1.5 mL tubes following the table below"
      table dilution_table
      check "Vortex and then spin down for a few seconds"
    }

    # TODO If any stocks too dilute, calculate volume needed to achieve 40 fmole/uL
    task_hashes.each do |task_hash|
      task_hash[:volumes] = task_hash[:stocks].map { |s| 1.0 }
    end

    # TODO volume checks. Ensure there is enough volume in each stock

    # TODO make stripwell, one well per reaction
    stripwells = produce spread task_hashes.map { |th| th[:stocks] }.flatten, "Stripwell", 1, 12

    # TODO make mastermix (1 uL ligase, 2 uL 10x "T4 DNA Ligase", 6 uL H2O)
    show do
      title "Make mastermix"

      check "Add 1 "
    end

    # TODO dispense 10 uL Mastermix into stripwell

    # TODO dispense 1 uL enzyme into stripwell

    # TODO dispense H20 to 20 uL

    # TODO dispense DNA

    # TODO spin down and put in thermocycler (37 C 1', 16 C 1') x 30, 55 C 5'

    io_hash[:task_ids].each do |tid|
      task = find(:task, id: tid)[0]
      set_task_status(task, "golden gate")
    end

    #io_hash[:golden_gate_result_ids] = golden_gate_results.collect { |g| g.id }

    return { io_hash: io_hash }
  end

end
