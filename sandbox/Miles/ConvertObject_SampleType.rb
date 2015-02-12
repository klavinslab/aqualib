needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol
  
  include Standard
  include Cloning
  
  def arguments
    {
    #Enter the plasmid stocks ids that you wish to convert to another plasmid 
    plasmidstock_ids: [18543],
    
    #Enter the corresponding plasmid you would like to convert the plasmid stock too
    plasmid_ids: [3981]
    }
  end
  
  def main
    stocks=input[:plasmidstock_ids]
    stocks_lengths=stocks.length
    stocks_full=find(:item, id: stocks)
    
    show{
      title: stocks_lengths
    }
    
    samps=input[:plasmid_ids]
    samps_full=find(:sample, id: samps)
  
    count=0
    while count < stocks_lengths do
      stocks_full[count].sample=samps_full[count]
      stocks_full[count].save
      count=count+1
    end
  end
  
end
  
