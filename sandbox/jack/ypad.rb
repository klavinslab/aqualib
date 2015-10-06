class Protocol
  
  def main
    o = op input
    
    o.input.all.take
    o.output.all.produce
    
    boo = o.output.all.item_ids
    
    show {
      title "Make YPAD Media"
      note "Description: Make 800 mL of yeast extract-peptone-dextrose medium + adenine (YPAD)"
    }
    
    show {
      title "Weigh Chemicals"
      note "Weight out yeast extract, peptone, dextrose, and adenine sulfate (and optional agar) and add to 1000 mL bottle"
    }
    
    show {
      title "Add diH2O"
      note "Add 500 mL dIH2O to bottle, close cap tightly and shake to mix"
    }
    
    show {
      title "Add Water and Mix"
      note "Add water to 800 mL mark on bottle, shake again to mix"
    }
    
    show {
      title "Label Bottle"
      note "Label the bottle with 'YPAD', 'Your initials', '#{ boo[0] }'"
    }
    
    o.input.all.release
    o.output.all.release

    return o.result

  
  end
  
end
