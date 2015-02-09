class Protocol
  
  include Standard
  include Cloning
  
  def argumnets
    {
    #Enter the plasmid stocks ids that you wish to convert to another plasmid 
    plasmidstock_ids: [],
    
    #Enter the corresponding plasmid you would like to convert the plasmid stock too
    plasmid_ids: [],
    }
  end
  
  def main
    stocks=input[:plasmidstock_ids]
    stocks_lengths=stocks.length
    stocks_full=find(:item, id: stocks)
    
    samps=input[:plasmid_ids]
    samps_full=find(:sample, id: samps)
  
    
    count=0
    while count < stocks_lengths do
      stocks_full[count].sample=samps_full[count]
      count=count+1
    end
  end
  
end
  
