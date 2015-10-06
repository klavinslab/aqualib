class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce
    
    id = o.output.media.item_ids
    type = o.input.parameter_names
   
    show {
      title "#{type[0]} Liquid Media"
      note "Description: This prepares a bottle of #{type[0]} Media for growing bacteria"
    }

    show {
      title "Get Bottle and Stir Bar"
      note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
    }
    
    show {
      title "Weight Out #{type[0]}" 
      note "Using the gram scale, large weigh boat, and chemical spatula, weigh out 20 grams of #{type[0]} media powder and pour into the bottle."
      warning "Before and after using the spatula, clean with ethanol"
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
      title "Label Media"
      note "Label the bottle with '#{type[0]} Liquid Media', 'Your initials', and '#{ id[0] }'"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
