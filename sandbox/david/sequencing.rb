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
   
    #parse plasmid ids
    plasmid_ids = input[:plasmid_ids]
    plasmid_uniq= plasmid_ids.uniq
    
    #parse primer ids
    primer_ids = input[:primer_ids]
    primer_uniq= primer_ids.uniq

    concentrations = []
    lengths = []
    length_bins = []
    

    plasmid_ids.each_with_index do |pid, index|
      info = plasmid_info pid
      concentrations.push info[:conc]
      lengths.push info[:length]
      
      length = info[:length]
      
      if length <6000
        length_bin=0
      elseif legnth >10000
        length_bin=2
      else
        length_bin=1
      end
      
      length_bins.push length_bin
      
    end




    show {
      note "#{length}"
      note "#{length_bin}"
    }

  
  end
  
end
