needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning


  def arguments
    {
      primer_stock_ids: []
    }
  end
  
  def main
    
    primer_stocks = input[:primer_stock_ids].collect{|pid| find(:item, id: pid )[0]}
    take primer_stocks, iteractive: true
    
    diluted_primers=[]
    table1= [["Aliquot IDs"]]
    table2= [["Aliquot IDs","Primer IDs to add"]]
    
    primer_stocks.each do |primer|
        
        j = produce new_sample primer.sample.name, of: "Primer", as: "Primer Aliquot"
        diluted_primers.push(j)
        table1.push([j.id])
        table2.push([j.id,primer.id])
        
    end
    
    num = diluted_primers.length
    
    show{
      check "Grab #{num} eppendorf tubes"
      check "Put a circular label sticker on the cap of each tube."
      check "Pipette 90ul of molecular grade water into each tube."
    }
    
    show{
      check "Label the eppendorf tubes according to the following table"
      table table1
    }
    
    show{
      check "Pipette 10ul from the Primer stock to the labeled aliquot tube according to the table below"
      table table2
    }
    
    release primer_stocks
    release diluted_primers
  end
end
