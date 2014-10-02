needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      elution_volume: 200,
      overnight_ids: []
    }
  end

  def main
    
    overnights = input[:overnight_ids].collect{|oid| find(:item,id:oid)[0]}
    take overnights, interactive: true
    
    num=overnights.length
    
    show{
      check "Label #{num} eppendorf tubes with IDs according to the table below"
      table overnight_ids
    }
    
    show{
      check "Pipet 1000 µL of culture from the overnight culutres into the corresponding labeled eppendorf tubes."
    }
    
    show{
      title "Spin down the cells"
      note "Spin at 5,800 xg for 2 minutes"
      warning "Make sure to balance the centrifuge. If you have an odd number of samples, use a balance tube with water"
    }
    
    show{
      title "Remove the supernatant"
      note "Pour off the supernaant into liquid waste, being sure not to upset the pellet. Pipette out the residual supernatant"
    }
    
    show{
      title "Resuspend in P1"
      note "Pipette 250 µL of P1 into each tube and vortex strongly to resuspend"
    }
    
    show{
      title "Be sure to check the boxs as you complete each step."
      check "Add P2 and gently invert to mix"
      check "Pipette 250 µL of P2 into each tube and gently invert 10 times to mix. Tube contents should turn blue."
      warning "This step should be done rapidly. Cells should not be exposed to active P2 for more than 5 minutes"
    }
    
    show{
    
      check "Add N3 and gently invert to mix"
      check "Pipette 350 µL of N3 into each tube and gently invert 10 times to mix. Tube contents should turn colorless."
      check "Spin tubes and set up columns and final tubes"
      check "Spin tubes at 17,000 xg for 10 minutes"
      warning "Make sure to balance the centrifuge. If you have an odd number of samples, use a balance tube with water"
      
      note "Meanwhile, prep and label all of the columns and tubes you will need for the rest of the protocol"
      check "Grab #{num} blue miniprep spin columns"
      check "Grab #{num} new eppendorf tubes"
      check "Label the side of the columns and the tops of the tubes according to the following table"
      table overnight_ids
    }
    
    show{
      title "Carefully pour the supernatant into the columns"
      note "The contents of each tube from the centrifuge should go into the similarly labeled column"
    }
    
    show{
      title "Be sure to check the boxs as you complete each step."
      check "Spin the columns"
      check "Spin at 17,000 xg for 1 minute"
      warning "Again, make sure the the centrifuge is balanced. Use an extra column with 500 µL of water if necessary"
      check "Wash the column with PE buffer"
      check "Remove the columns from the centrifuge and discard the flow through into a liquid waste container"
      warning "Make sure the PE bottle that you are using as ethanol added!"
      check "Add 750 µL of PE buffer to each column."
      check "Close the PE bottle tightly."
      check "Spin the columns at 17,000 xg for 1 minute"
    }
    
    
    
  end
    
end
