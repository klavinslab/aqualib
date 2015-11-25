class Protocol
  
  def main
    o = op input
    
    o.output.all.produce
    label = "SDO -leu (unsterile)"
    
    ingredients = find(:item,{object_type:{name:"Adenine (Adenine hemisulfate)"}}) + 
        find(:item,{object_type:{name:"Dextrose"}}) + find(:item,{object_type:{name:"Yeast Nitrogen Base Without Amino Acids"}}) 
            
    if label.include?("agar")
      ingredients += find(:item, {object_type:{name:"Bacto Tryptone"}})
    
    typeSDO = label.scan(/-[a-z]+/)
    acids = typeSDO.collect{|x| x.gsub(/-/, '')}
    includeAcids = ["leu", "his", "trp", "ura"] - acids
    includeAcids.each do |i|
      if(i == "leu")
        ingredients += find(:item,{object_type:{name:"Leucine Solution"}})
      elsif(i == "his")
        ingredients += find(:item,{object_type:{name:"Histidine Solution"}})
      elsif(i == "trp")
        ingredients += find(:item,{object_type:{name:"Tryptophan Solution"}})
      else
        ingredients += find(:item,{object_type:{name:"Uracil Solution"}})
    end
    
    take ingredients, interactive: true
    item_id = o.output.all.item_ids
    #parameters
    #param = o.input.parameter_names
    
    #get array of just amino acid parameters
    #acids = param - ["agar"]
    
    #get array of not included amino acids
    #label_array = ["Leu", "His", "Trp", "Ura"] - acids
      
    #modify label for bottle depending on # of amino acids and presence of agar
    #if acids.length == 4
    #  label = "SC Media #{label.include?("agar") ? " + Agar" : ""}"
    #else
    #  label = "SDO -#{label_array.join(" -")} #{param.include?("agar") ? " + Agar" : ""}"
    #end
    
    show {
      title "#{label}"
      note "Description: Makes 800 mL of #{label} media with 2% glucose and adenine supplement"
    }
    
    show {
      title "Get Bottle and Stir Bar"
      note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
    }
    
    show {
      title "Weigh Chemicals"
      note "Weight out 5.36g nitrogen base, 1.12g of DO media, 16g of dextrose, .064g adenine sulfate#{label.include?("agar") ? ", 16g tryptone" : ""} and add to 1000 mL bottle"
    }
    
    show {
      title "Add Amino Acid"
      note "Add 8 mL of #{acids.join(", ")} solutions each to bottle"
    }

    show {
      title "Measure Water"
      note "Take the bottle to the DI water carboy and add water up to the 800 mL mark"
    }
    
    show {
      title "Mix solution"
      note "Shake until most of the powder is dissolved."
      note "It is ok if a small amount of powder is not dissolved because the autoclave will dissolve it"
    }
    
    show {
      title "Cap Bottle"
      note "Place cap on bottle loosely"
    }
    
    show {
      title "Label Bottle"
      note "Label the bottle with '#{label.gsub(/(unsterile)/, '')}', 'Date', 'Your initials', '#{item_id[0]}'"
    }
    
    release ingredients, interactive: true
    o.output.all.release

    return o.result

  
  end
  
end
