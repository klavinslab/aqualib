class Protocol

  def main
    o = op input

    o.input.all.take
    o.output.all.produce

    show {
      title "M9 Minimal Growth Media"
      note "Description: This prepares a 250 mL bottle of M9 Minimal Media"
      note "Total duration: 10 minutes"
      note "Total worktime: 10 minutes"
      warning "Antibiotics: To add antibotics, wait for contents to cool to 40 C and add the appropriate amount of antibiotics"
      warning "Nutrients: To add nutrients, reduce the amount of water added and replace with solution of the desired nutrients"
    }
    
    show {
      title "Using the serological pipette and 25 mL tip, add 50 mL of 5x M9 salts to the 500 mL bottle"
    }
    
    show {
      title "Using the serological pipette and 5 mL tip, add 2.5 mL of 100x MgSO4 CaCl2 solution"
      }
      
    show {
      title "Using the P1000 pipette, add 1 mL of 250x biotin"
    }
    
    show {
      title "Fill to the 250 mL line with sterile water"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
