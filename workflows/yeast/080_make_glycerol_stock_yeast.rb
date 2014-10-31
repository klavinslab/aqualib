needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def debug
    true
  end

  def arguments
    {
      "overnight_ids Lysate" =>[0],
      "overnights Yeast Overnight Suspension" =>[0]
    }
  end
  
  def main
      overnights = input[:overnight_ids].collect {|yid| find(:item, id: yid )[0]}
      take overnights
      glycerol = choose_object "50 percent Glycerol (sterile)", take: true
      glycerol_stocks = overnights.collect {|y| produce new_sample y.sample.name, of: "Yeast Strain", as: "Yeast Glycerol Stock"}

      show {
        title "Pipette 900 µL of 50 percent Glycerol into Cyro tube(s)."
        check "Take #{overnights.length} Cryo #{"tube".pluralize(overnights.length)}"
        check "Label each tube with #{(glycerol_stocks.collect {|y| y.id}).join(", ")}"
        check "Pipette 900 µL of 50 percent Glycerol into each tube."
        warning "Make sure not to touch the inner side of the Glycerol bottle with the pipetter."
      }

      tab = [["Overnight id","Cryo tube id"]]
      overnights.each_with_index do |y, idx|
        tab.push([y.id,glycerol_stocks[idx].id])
      end

      show {
          title "Add overnight suspensions to Cyro tube"
          check "Pipette 900 µL of yeast overnight into a Cyro tube according to the following table."
          table tab
          check "Cap the Cryo tube and then vortex on a table top vortexer for about 20 seconds"
        }
        
        release overnights + [glycerol], interactive: true
        release glycerol_stocks, interactive: true, method: "boxes"
        
  end
  
end
