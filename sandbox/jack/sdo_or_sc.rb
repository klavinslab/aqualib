class Protocol
  
  def main
    o = op input
    
    o.input.all.take
    o.output.all.produce
    
    acids = o.input.parameter_names
    check = ["Leu", "His", "Trp", "Ura"]
    label_array = check - acids
    
    if acids.include?("agar")
      agar = ", 16g tryptone"
    else 
      agar = ""
    end
      
    if acids.length == 4
      label = "SC Media"
    else
      label = "SDO -#{label_array.join("', '-")} #{agar}"
    end
    
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
      note "Weight out 5.36g nitrogen base, 1.12g of DO media, 16g of dextrose, .064g adenine sulfate #{agar} and add to 1000 mL bottle"
    }
    
    show {
      title "Add Amino Acid"
      note "Add 8 mL of #{boo.join(", ")} solutions each to bottle"
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
      note "Label the bottle with '#{label}', 'date', 'Your initials'"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
