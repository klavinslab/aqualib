class Protocol
  
  def main
    o = op input
    
    o.input.all.take
    o.output.all.produce
    
    
    #include a check for non included reagents (reverse)
    boo = o.input.all.parameter_names
    
    show {
      title "Get Bottle and Stir Bar"
      note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
    }
    
    show {
      title "Make SDO or SC Media"
      note "Description: Makes 800 mL of synthetic dropout (SDO) or synthetic complete (SC) media with 2% glucose and adenine supplement (800mL)"
    }
    
    show {
      title "Weigh Chemicals"
      note "Weight out 5.36 grams of nitrogen base, 1.12 grams of DO media, 16 grams of dextrose, and .064 grams of adenine sulfate and add to 1000 mL bottle"
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
      note "Label the bottle with 'YPAD', 'Your initials', '#{ boo.join("', ') }'"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
