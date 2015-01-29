needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      plasmid_stock_ids: [5392,5389,5350],
      fragment_ids: [],
      debug_mode: "No"
    }
  end

  def main
    io_hash = input[:io_hash]
    io_hash = input if input[:io_hash].empty?  
    io_hash[:group]  = input[:group] || "technicians"
    if io_hash[:debug_mode].downcase == "yes"
      def debug
        true
      end
    end
    fragment_ids = []
    # add fragment_ids from protocol or metacol
    fragment_ids.concat input[:fragment_ids] || []
    # Pull info from Gibson assembly tasks which fragment needs to work on
    gibson_info = gibson_assembly_status
    fragment_ids.concat gibson_info[:fragments][:not_ready_to_build] if gibson_info[:fragments]
    # Pull info from Fragment Construction tasks which fragment needs to work on
    fragment_construction = fragment_construction_status
    waiting_ids = task_group_filter(fragment_construction[:waiting_ids], io_hash[:group])
    waiting_ids.each do |tid|
      task = find(:task, id: tid)[0]
      fragment_ids.concat task.simple_spec[:fragments]
    end
    plasmids = fragment_ids.collect{|f| find(:sample, id: f)[0].properties["Template"]}
    # remove redundant plasmids 
    plasmids = plasmids.compact.uniq
    plasmids_need_to_dilute = plasmids.select{ |p| p.in(p.sample_type.name + " Stock").length > 0 && p.in("1 ng/µL " + p.sample_type.name + " Stock").length == 0 }
    plasmid_stocks = plasmids_need_to_dilute.collect{ |p| p.in(p.sample_type.name + " Stock")[0] }
    # concat with input to this protocol if input[:plasmid_stock_ids] is defined
  	plasmid_stocks.concat input[:plasmid_stock_ids].collect{ |fid| find(:item, id: fid)[0] } if input[:plasmid_stock_ids]
    if plasmid_stocks.length == 0
      show {
        title "No plasmid or fragment stocks need to be diluted"
        note "Thanks for you efforts! Please work on the next protocol!"
      }
      io_hash[:plasmid_diluted_stock_ids]  = []
      return { io_hash: io_hash }
    end
    # take all items
  	take plasmid_stocks, interactive: true, method: "boxes"
    # measure concentration for those have no concentration recorded in datum field
    plasmid_stocks_need_to_measure = plasmid_stocks.select {|f| !f.datum[:concentration]}
    while plasmid_stocks_need_to_measure.length > 0
      data = show {
        title "Nanodrop the following plasmid/fragment stocks."
        plasmid_stocks_need_to_measure.each do |ps|
          get "number", var: "c#{ps.id}", label: "Go to B9 and nanodrop tube #{ps.id}, enter DNA concentrations in the following", default: 100
        end
      }
      plasmid_stocks_need_to_measure.each do |ps|
        ps.datum = {concentration: data[:"c#{ps.id}".to_sym]}
        ps.save
      end
      plasmid_stocks_need_to_measure = plasmid_stocks.select {|f| !f.datum[:concentration]}
    end
    # collect all concentrations
    concs = plasmid_stocks.collect {|f| f.datum[:concentration].to_f}
  	water_volumes = concs.collect {|c| c-1}
    # produce 1 ng/µL Plasmid Stocks
    plasmid_diluted_stocks = plasmid_stocks.collect {|f| produce new_sample f.sample.name, of: f.sample.sample_type.name, as: ("1 ng/µL " + f.sample.sample_type.name + " Stock") }
    # build a checkable table for user
    tab = [["Newly labled tube","Plasmid/Fragment stock, 1 µL","Water volume"]]
  	plasmid_stocks.each_with_index do |f,idx|
  		tab.push([plasmid_diluted_stocks[idx].id, { content: f.id, check: true }, { content: water_volumes[idx].to_s + " µL", check: true }])
  	end
  	show {
  		title "Make 1 ng/µL Plasmid/Fragment Stocks"
  		check "Grab #{plasmid_stocks.length} 1.5 mL tubes, label them with #{plasmid_diluted_stocks.collect {|f| f.id}}"
  		check "Add plasmid stocks and water into newly labeled 1.5 mL tubes following the table below"
  		table tab
  		check "Vortex and then spin down for a few seconds"
  	}

  	release plasmid_stocks + plasmid_diluted_stocks, interactive: true, method: "boxes"

    io_hash[:plasmid_diluted_stock_ids]  = plasmid_diluted_stocks.collect {|p| p.id}
    return { io_hash: io_hash }

  end

end

