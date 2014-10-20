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
      debug_mode: "Yes"
    }
  end

  def main
    io_hash = {}
    # io_hash = input if input[:io_hash].empty?
    io_hash[:debug_mode] = input[:debug_mode]
    io_hash[:task_mode] = input[:task_mode]
    if io_hash[:debug_mode] == "Yes"
      def debug
        true
      end
    end
    # choose from Gibson assembly tasks which template needs to be diluted to 1ng/µL.
    gibson_info = gibson_assembly_status
    fragment_not_ready_to_build_ids = []
    fragment_not_ready_to_build_ids.concat input[:fragment_ids] # add fragment_ids from protocol or metacol
    fragment_not_ready_to_build_ids = gibson_info[:fragments][:not_ready_to_build] if gibson_info[:fragments]
    plasmids = fragment_not_ready_to_build_ids.collect{|f| find(:sample, id: f)[0].properties["Template"]}
    plasmids = plasmids.compact
    plasmids_need_to_dilute = plasmids.select{|p| p.in("Plasmid Stock").length > 0 && (p.in("1 ng/µL Plasmid Stock").length == 0)}
    plasmid_stocks = plasmids_need_to_dilute.collect{|p| p.in("Plasmid Stock")[0]}
    # concat with direct input to this protocol if input[:plasmid_stock_ids] is defined
  	plasmid_stocks.concat input[:plasmid_stock_ids].collect{|fid| find(:item, id: fid)[0]} if input[:plasmid_stock_ids]
    if plasmid_stocks.length == 0
      show {
        title "No plasmid stocks need to be diluted"
        note "Thanks for you efforts! Please work on the next protocol!"
      }
      return { plasmid_diluted_stock_ids: [] }
    end
    # take all items
  	take plasmid_stocks, interactive: true, method: "boxes"
    # measure concentration for those have no concentration recorded in datum field
    plasmid_stocks_need_to_measure = plasmid_stocks.select {|f| not f.datum[:concentration]}
    if plasmid_stocks_need_to_measure.length > 0
      data = show {
        title "Nanodrop the following plasmid stocks."
        plasmid_stocks_need_to_measure.each do |ps|
          get "number", var: "c#{ps.id}", label: "Go to B9 and nanodrop tube #{ps.id}, enter DNA concentrations in the following", default: 30.2
        end
      }
      plasmid_stocks_need_to_measure.each do |ps|
        ps.datum = {concentration: data[:"c#{ps.id}".to_sym]}
        ps.save
      end
    end
    # collect all concentrations
    concs = plasmid_stocks.collect {|f| f.datum[:concentration].to_f}
  	water_volumes = concs.collect {|c| c-1}
    # produce 1 ng/µL Plasmid Stocks
    plasmid_diluted_stocks = plasmid_stocks.collect {|f| produce new_sample f.sample.name, of: "Plasmid", as: "1 ng/µL Plasmid Stock"}
    # build a checkable table for user
    tab = [["Newly labled tube","Plasmid stock, 1 µL","Water volume"]]
  	plasmid_stocks.each_with_index do |f,idx|
  		tab.push([plasmid_diluted_stocks[idx].id, { content: f.id, check: true }, { content: water_volumes[idx].to_s + " µL", check: true }])
  	end
  	show {
  		title "Make 1 ng/µL Plasmid Stocks"
  		check "Grab #{plasmid_stocks.length} 1.5 mL tubes, label them with #{plasmid_diluted_stocks.collect {|f| f.id}}"
  		check "Add plasmid stocks and water into newly labeled 1.5 mL tubes following the table below"
  		table tab
  		check "Vortex and then spin down for a few seconds"
  	}

  	release plasmid_stocks + plasmid_diluted_stocks, interactive: true, method: "boxes"

  	return { plasmid_diluted_stock_ids: plasmid_diluted_stocks.collect {|p| p.id} }

  end

end

