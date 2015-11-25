class Protocol
  
  def main
    o = op input
    
    o.input.all.take
    o.output.all.produce
    
    ingredients = find(:item, { object_type: { name: "Adenine (Adenine hemisulfate)" } } ) + 
        find(:item, { object_type: { name: "Dextrose" } } ) + find(:item, { object_type: { name: "Bacto Yeast Extract" } } ) +
            find(:item, { object_type: { name: "Bacto Tryptone" } } )
    take ingredients, interactive: true
    item_id = o.output.all.item_ids
    
    show {
      title "Make YPAD Media"
      note "Description: Make 800 mL of yeast extract-tryptone-dextrose medium + adenine (YPAD)"
    }
    
    show {
      title "Weigh Chemicals"
      note "Weight out 8g yeast extract, 16g tryptone, 16g dextrose, .064g adenine sulfate and add to 1000 mL bottle"
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
      note "Label the bottle with 'YPAD', 'Your initials', '#{item_id[0]}'"
    }
    
    release itemOne, interactive: true
    o.output.all.release

    return o.result

  
  end
  
end
