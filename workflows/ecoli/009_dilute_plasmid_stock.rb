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
      plasmid_stock_ids: [27259,27507,9189]
    }
  end

  def main
  	plasmid_stocks = input[:plasmid_stock_ids].collect{|fid| find(:item, id: fid)[0]}
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

