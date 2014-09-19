needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      #"cultures_ids Yeast 50ml culture" => [0],
      culture_ids: [0], 
      aliquots_number: [0]
    }
  end

  def main

    l = choose_object "100 mM LiOAc"
    water = choose_object "50 mL Molecular Grade Water aliquot"
    
    cultures = input[:culture_ids].collect{|cid| find(:item,id:cid)[0]}
    take cultures, interactive: true
    
    culture_labels=[["Tube Number","Label"]]
    tube_labels=[["Label"]]
    tube_number=1
    cultures.each do |culture|
      culture_labels.push([tube_number,culture.id])
      tube_labels.push([tube_number])
      tube_number=tube_number+1
    end
    
    show{
      title "Preperation Step"
      note "Label a set of eppendorf tubes and 50ml Falcon tubes according to the following table"
      table tube_labels
    }
    
    show{
      title "Harvesting Cells"
      check "Pour contents of flask into the labeled 50ml plastic falcon tube according to the tabel below"
      note "It does not matter if you dont get the foam into the tubes"
      table culture_labels
    }
    
    show{
      title "Harvesting Cells"
      check "Balance the 50ml Falcon tube(s) so that they all weigh approximately (within 0.1g) the same."
      check "Load the 50ml plastic falcon tube(s) into the large table top centerfuge such that they are balanced."
      check "Set the speed to 3000xg" 
      check "Set the time to 5 minutes"
      warning "MAKE SURE EVERYTHING IS BALANCED"
      check "Hit start"
      note "If you have never used the centerfuge before, or are unsure about any aspect of what you have just done ASK A MORE EXPERIENCED LAB MEMBER BEFORE YOU HIT START!"
    }
    
    show{
      title "Harvesting Cells"
      check "After spin take out falcon tubes and take them in a rack to the sink at the tube washing station without shaking tubes and pour out liquid from tubes in one smooth motion so as not to disturb cell pellet then recap tubes and take back to bench."
    }
    
    show{
      title "Making cells competent: Water wash"
      check "Add 1ml of molecular grade H2O to each falcon tube and recap"
      check "Vortex the tubes till cell pellet is resuspended"
      check "Aliquot UPTO 1.5ml of the volume from each falcon tube into the correctly labeled 1.5ml ependorf tube that were set aside earlier."
      note "Its ok if you have more than 1.5ml of the resuspension. 1.5ml is enough"
    }
    
    show{
      title "Making cells competent: LiAcO wash"
      check "Load the 1.5ml ependorf tubes into the table top centerfuge and spin down for 20 seconds or till cells are pelleted"
      check "Use a pipette and remove the supernatant from each tube without disturbing the cell pellet."
      check  "Add 1ml of 100mM Lithium Acetate to each ependorf tube and recap"
      check "Vortex the tubes till cell pellet is resuspended"
    }
    
    show{
      title "Making cells competent: Resuspension"
      check "Load the 1.5ml ependorf tubes into the table top centerfuge and spin down for 20 seconds or till cells are pelleted"
      check "Use a pipette and remove the supernatant from each tube without disturbing the cell pellet."
    }
    
    show{
      title "Making cells competent: Resuspension"
      check "Estimate the pellet volume using the gradations on the side of the eppendorf tube for each tube."
      check "Add 4 pellet volumes of 100mM Lithium Acetate to the ependorf tube for each tube."
      check "Vortex the tubes till cell pellet is resuspended"
      note "The 0.1 on the tube means 100ul and each line is another 100ul"
    }
    
    yeast_compcell_aliquot_id_table=[["Aliquot Number","Comp cell aliquot IDs"]]
    yeast_compcell_aliquot_id=[]
    counter=0
    cultures.each do |culture|
    
      num = input[:aliquots_number][counter]
      counter2=0
      culture_id = culture[:id]
  
      while counter2<num

        j = produce new_sample culture.sample.name, of: "Yeast Strain", as: "Yeast Competent Aliquot"
        
        tubenum=counter2+1
        yeast_compcell_aliquot_id_table.push([tubenum,j[:id]])
        yeast_compcell_aliquot_id.push([j[:id]])
        counter2 = counter2 + 1
      end
      
      show{
        title "Aliquoting cells"
        check "Label ependorf tubes for comp cells according to the tabel below"
        check "Aliquot 50ul of the #{culture[:id]} resuspension into the eppendorf tubes"
        table yeast_compcell_aliquot_id_table
      }
      counter = counter + 1
      
    end
    
    release [l]
    release [water]
    release cultures
    
    return {yeast_compcell_aliquot_id: yeast_compcell_aliquot_id}
    
  end

end
