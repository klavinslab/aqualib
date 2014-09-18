#hi
needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
  include Standard
  include Cloning
  
  def debug
    false
  end
  
  def arguments 
    plasmid_ids: (SampleType.where("name='Plasmid'")[0].samples.collect { |p| p.id }).sample(10)
    #plate_types: 
  end
  
  def main
    #data = show {
    #  title "Hello World!"
    #  title "An input example."
    #  get "text", var: "y", label:"Enter a string", default: "hi again"
    #}
    
    #y = data[:y]

    show {
      title "Initialize the Electroporator"
      note  "If the electroporator is off (no numbers displayed), turn it on using the ON/STDBY button."
      note  "Turn on the electroporator if it is off and set the voltage to 1250V by clicking up and down button.\nClick the time constant button."
    }
    
    show {
      title "Arrange Ice Block"
      note "You will next retrieve a styrofoam ice block and an aluminum tube rack.\nPut the aluminum tube rack on top of the ice block."
      image "arrange_cold_block"
    }
    
    show {
      title "Retrieve Cuvette and Electrocompetent Cells"
      note "You will next retrieve a Clean Electrocuvette, put it inside the styrofoam touching ice block.\nThen grab a tube of electrocompetent cells and put it on the aluminum tube rack."
      image "handle_electrocompetent_cells"
      warning "The cuvette metal sides should be touching the ice block to keep it cool."
    }

    show {
      title "Which comp cells"
    }
    
    show {
      title "Allow the Electrocompetent cells to thaw slightly"
      note "Wait about 15-30 seconds until the cells have thawed to a slushy consistency"
      warning "Transformation efficiency depends on keeping ecomp cells ice-cold until electroporation"
      image "thawed_electrocompotent_cells"
    }




  end
end
