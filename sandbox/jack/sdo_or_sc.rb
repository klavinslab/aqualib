class Protocol
  
  def main
    o = op input
    
    o.input.all.take
    o.output.all.produce
    
    boo = o.input.all.parameter_names
    
    show {
      title "Make SDO or SC Media"
      note "Description: Makes 800 mL of synthetic dropout (SDO) or synthetic complete (SC) media with 2% glucose and adenine supplement (800mL)"
    }
    
    show {
      title "Weigh Chemicals"
      note "Weight out nitrogen base, DO media, dextrose, and adenine sulfate and add to 1000 mL bottle"
    }
    
    show {
      title "Add Amino Acid"
      note "Add amino acid solutions (Leu/His/Trp/Ura) to bottle (based on dropout type)"
    }
    
    show {
      title "Add dlH2O"
      note "Add 500 mL dIH2O to bottle, close cap tightly and shake to mix"
    }

    show {
      title "Add Water"
      note "Add water to 800 mL mark on bottle, shake again to mix"
    }
    
    show {
      title "Cap Bottle"
      note "Place cap on bottle loosely"
    }
    
    show {
      title "Label Bottle"
      note "Label the bottle with 'YPAD', 'Your initials', '#{ boo.join(", ") }'"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
