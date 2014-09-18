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
    initials: "First and last initial"
    plasmid_item_ids: [9976, 10575, 10576],
    primer_ids: [2064, 2064, 2064]
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
        plasmid_volume.push (800/info[:conc]).round(1)
        water_volume.push 12.5-(800/info[:conc]).round(1)
      end
   
    end


    # initilize plasmid and primer stocks array
        plasmid_stocks = []
        plasmid_uniq.each do |pid|
          plasmid = find(:sample,{id: pid})[0]
          plasmid_stock = plasmid.in "Plasmid Stock"
          plasmid_stocks.push plasmid_stock[0] if plasmid_stock[0]
        end
    
        primer_aliquots = []
        primer_uniq.each do |prid|
          primer = find(:sample,{id: prid})[0]
          primer_aliquots = primer.in "Primer Aliquot"
          primer_aliquots.push primer_aliquots[0] if primer_aliquots[0]
        end

    take plasmid_stocks + primer_aliquots, interactive: true,  method: "boxes"


    sequencing_reactions = []







    show {
      note "#{plasmid_ids}"
      note "#{primer_aliquots}"
      note "#{plasmid_volume}"
      note "#{water_volume}"
    }


  
  end
  
end
