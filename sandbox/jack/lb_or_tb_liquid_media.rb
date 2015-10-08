class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce
    
    id = o.output.media.item_ids
    type = o.input.parameter_names
    
    if type[0] == "LB Agar"
      amount = 29.6
    elsif (type[0] == "LB Liquid Media") || (type[0] == "TB Liquid Media")
      amount = 20
    else 
      raise ArgumentError, "Parameter is not valid"
   
    show {
      title "#{type[0]}"
      note "Description: This prepares a bottle of #{type[0]} for growing bacteria"
    }

    show {
      title "Get Bottle and Stir Bar"
      note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
    }
    
    show {
      title "Weight Out #{type[0]}" 
      note "Using the gram scale, large weigh boat, and chemical spatula, weigh out #{amount} grams of #{type[0]} powder and pour into the bottle."
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
      note "Label the bottle with '#{type[0]}', 'Your initials', and '#{id[0]}'"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
