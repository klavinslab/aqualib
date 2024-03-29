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
    initials: "First and last initial",
    plasmid_item_ids: [9976, 10575, 10576],
    primer_ids: [2064, 2064, 2064],
    genewiz_tracking_number: "00-000000000"
    }  
  end
  
  
  def plasmid_info pid
    plasmid = find(:sample,{id: pid})[0]# Sample.find(fid)
    length = plasmid.properties["Length"]
    stock = plasmid.in "Plasmid Stock"
    conc = stock[0].datum[:concentration]
    return {
      plasmid: plasmid,
      length: length,
      stock: stock[0],
      conc: conc
    }
  end
  
  
  def main
   
    #parse initials
    initials = input[:initials]
   
    #parse plasmid item ids
    plasmid_item_ids = input[:plasmid_item_ids]
    plasmid_ids = []
    plasmid_item_ids.each do |pid|
      plasmid_ids.push find(:item, id: pid)[0].sample
    end
    plasmid_uniq= plasmid_ids.uniq
    
    #parse primer ids
    primer_ids = input[:primer_ids]
    primer_uniq= primer_ids.uniq

    #parse genewiz tracking number
    tracking_number = input[:genewiz_tracking_number]

    concentrations = []
    lengths = []
    plasmid_volume = []
    water_volume = []
    

    plasmid_ids.each do |pid|
      info = plasmid_info pid
      concentrations.push info[:conc]
      lengths.push info[:length]
      
      #Bin the plasmid lengths according to genewiz specifications
      if info[:length] <6000
        plasmid_volume.push (500/info[:conc]).round(1)
        water_volume.push 12.5-(500/info[:conc]).round(1)
      elsif info[:length] >10000
        plasmid_volume.push (1000/info[:conc]).round(1)
        water_volume.push 12.5-(1000/info[:conc]).round(1)
      else
        plasmid_volume.push (800.0/info[:conc]).round(1)
        water_volume.push 12.5-(800.0/info[:conc]).round(1)
      end
   
    end


    # initilize plasmid and primer stocks array
        plasmid_stocks_unique = []
        plasmid_uniq.each do |pid|
          plasmid = find(:sample,{id: pid})[0]
          plasmid_stock = plasmid.in "Plasmid Stock"
          plasmid_stocks_unique.push plasmid_stock[0] if plasmid_stock[0]
        end
        
        plasmid_stocks = []
        plasmid_ids.each do |pid|
          plasmid = find(:sample,{id: pid})[0]
          plasmid_stock = plasmid.in "Plasmid Stock"
          plasmid_stocks.push plasmid_stock[0] if plasmid_stock[0]
        end
    
        primer_aliquots = []
        primer_ids.each do |prid|
          primer = find(:sample,{id: prid})[0]
          primer_aliquot = primer.in "Primer Aliquot"
          primer_aliquots.push primer_aliquot[0] if primer_aliquot[0]
        end
        
        primer_aliquots_unique = []
        primer_uniq.each do |prid|
          primer = find(:sample,{id: prid})[0]
          primer_aliquot = primer.in "Primer Aliquot"
          primer_aliquots_unique.push primer_aliquot[0] if primer_aliquot[0]
        end
        

    take plasmid_stocks_unique + primer_aliquots_unique, interactive: true,  method: "boxes"

    plasmid_item_with_volume = plasmid_stocks.map.with_index {|t,i| plasmid_volume[i].to_s + " ul of " + t.id.to_s}
    water_with_volume = water_volume.collect { |v| v.to_s + " ul of water"}
    primer_with_volume = primer_aliquots.map {|j| "2.5 ul of " + j.id.to_s}
      
      
    tab = []
    tab.push water_with_volume
    tab.push plasmid_item_with_volume
    tab.push primer_with_volume
    tab_check =  tab.collect { |row| row.collect { |e| { content: e, check: true } } }
    col1 = [ "Well", "Water", "Template", "Primer" ]  
    rest = (1..tab_check.transpose.length).collect { |i| [i].concat(tab_check.transpose[i-1]) }
    total = rest.unshift(col1)
      
    num = plasmid_ids.length
    num2 = format('%02d', num)
    stripwell_tubes = (((num).to_f)/12).ceil
    last_well = (num-1)%12+1
    
      
    show {
      title "Get stripwell tubes and label them"
      note "Grab #{stripwell_tubes} stripwell tubes"
      note "Label well 1 of stripwell 1 with ''#{initials}01'' as in the example image below"
      note "Label well #{last_well} of stripwell #{stripwell_tubes} with ''#{initials}#{num2}''"
      note "Label the first and last well of each stripwell tube (if not already labeled) with ''#{initials} + well number''"
    }
      
      
      
    show {
      title "Add the following to the stripwell tubes"
      table total
    }

    show {
      title "Put the tubes in the Genewiz mailbox"
      note "Cap all of the stripwell tubes"
      note "Put the stripwell tubes into a zip-lock bag along with the Genewiz order form with tracking number #{tracking_number}"
      note "Ensure that the bag is sealed, and put it into the Genewiz mailbox"
    }

  
  release plasmid_stocks + primer_aliquots_unique, interactive: true,  method: "boxes"
  
  end
  
end
