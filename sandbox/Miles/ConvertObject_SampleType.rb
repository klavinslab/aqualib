needs "aqualib/lib/cloning"
needs "aqualib/lib/standard"

class Protocol
  
  include Standard
  include Cloning
  
  def arguments
    {
    #Enter the plasmid stocks ids that you wish to convert to another plasmid 
    plasmidstock_ids: [17032,17034,17039],
    
    #Enter the corresponding plasmid you would like to convert the plasmid stock too
    plasmid_ids: [3546, 3547, 3539]
    }
  end
  
  def main
    stocks=input[:plasmidstock_ids]
    stocks_lengths=stocks.length
    #stocks_full=find(:item, id: stocks)
    
    samps=input[:plasmid_ids]
    #samps_full=find(:sample, id: samps)
  
    count=0
    while count < stocks_lengths do
        idnum=stocks[count]
        idnumsamp=samps[count]
    
        stock=find(:item, id: idnum)
        samp=find(:sample, id: idnumsamp)
        
        raise "Sample type needs to be the same" if stock[0].sample.sample_type.name != samp.sample_type.name
      
    	  
    	  stock[0].sample=samp[0]
        stock[0].save
        
    	  count=count+1
  	end
  end
  
end
  
