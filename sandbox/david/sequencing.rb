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
    plasmid_ids: [2071],
    primer_ids: [2064]
    }  
  end
  
  
  def plasmid_info fid
    plasmid = find(:sample,{id: fid})[0]# Sample.find(fid)
    length = plasmid.properties["Length"]
    stock = plasmid.in "Fragment Stock"
    conc = stock[0].datum[:concentration]
    return {
      plasmid: plasmid,
      length: length,
      stock: stock[0],
      conc: conc
    }
  end
  
  
  
  def main
   
    #parse plasmid ids
    plasmid_ids = input[:plasmid_ids]
    plasmid_uniq= plasmid_ids.uniq
    
    #parse primer ids
    primer_ids = input[:primer_ids]
    primer_uniq= primer_ids.uniq

    plasmid_ids.each_with_index do |fid, index|
      info = plasmid_info fid
    end

    
    show {
      note "#{info}"
    }

  
  end
  
end
