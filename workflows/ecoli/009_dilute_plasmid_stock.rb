needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      io_hash: {},
      plasmid_stock_ids: [27259,27507,9189],
      debug_mode: "Yes",
      task_mode: "Yes"
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
    plasmid_stocks = []
    if io_hash[:task_mode] == "Yes"
      gibson_info = gibson_assembly_status
      fragment_not_ready_to_to_build_ids = []
      fragment_not_ready_to_build_ids = gibson_info[:fragments][:not_ready_to_build] if gibson_info[:fragments]
      plasmids = fragment_not_ready_to_to_build_ids.collect{|f| find(:sample, id: f)[0].properties["Template"]}
      plasmids = plasmids.compact
      plasmids_need_to_dilute = plasmids.select{|p| p.in("Plasmid Stock") && (not p.in("1 ng/µL Plasmid Stock"))}
      plasmid_stocks = plasmids_need_to_dilute.collect{|p| p.in("Plasmid Stock")}
    end
    show {
      title "Testing page"
      note "#{plasmid_stocks.collect{|p| p.id}}"
    }
  	plasmid_stocks.concat input[:plasmid_stock_ids].collect{|fid| find(:item, id: fid)[0]}
  	take plasmid_stocks, interactive: true, method: "boxes"
  	plasmid_diluted_stocks = plasmid_stocks.collect {|f| produce new_sample f.sample.name, of: "Plasmid", as: "1 ng/µL Plasmid Stock"}
  	tab = [["Newly labled tube","Plasmid stock, 1 µL","Water volume"]]
  	concs = plasmid_stocks.collect {|f| f.datum[:concentration].to_f}
  	water_volumes = concs.collect {|c| c-1}
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

