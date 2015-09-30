
class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce

    show {
      title "TB Liquid Media"
      note "Description: This prepares a bottle of TB Media for growing bacteria"
      warning "To add antibotics, wait for contents to cool to 40 C and add the appropriate amount of antibiotics"
    }
    
    show {
      title "Zero Scale"
      note "Place large weigh boat on gram scale and zero"
    }
    
    show {
      title "Weigh TB Powder"
      note "Measure out 20 grams of TB media powder and pour contents into liter bottle"
      }
      
    show {
      title "Measure Water"
      note "Measure out 800 mL of DI water using the graduated cyinder and pour into liter bottle"
    }
    
    show {
      title "Mix Solution"
      note "Close liter bottle and shake until all contents are solvated"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end

