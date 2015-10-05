class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce
    
    boo = output.all.item

    show {
      title "LB Agar"
      note "Description: This protocol is for the preperation of LB Agar, the common plate media for growing bacteria cells."
    }
    
    show {
      title "Get Bottle and Stir Bar"
      note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
    }
    
    show {
      title "Weigh Agar"
      note "Using the gram scale, large weigh boat, and chemical spatula, weigh out 29.6 grams of LB Agar powder and pour into the bottle."
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
      note "Label the bottle with '\LB Liquid Media\', \'Your initials\', and \'#{boo}\'"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
