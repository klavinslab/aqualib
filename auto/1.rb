class Protocol

  def main

    o = op input
    o.input.all.take
    stripwells = o.output.fragment.new_collections

    ingredients = Table.new(
      well: "Well",
      fwd: "Forward Primer ID",
      rev: "Reverse Primer ID",
      template: "Template ID",
      template_vol: "Template Volume",
      mix_vol: "Master Mix Volume",
      water_vol: "Water Volume")

    o.threads.spread(stripwells) do |t, slot| 
      t.output.fragment.associate slot
      ingredients
        .well(slot.col+1)
        .fwd(t.input.fwd.item_id)
        .rev(t.input.rev.item_id)
        .template(t.input.template.item_id)
        .template_vol(1+0.1*t.index)
        .mix_vol(3.0)
        .water_vol(10-0.1*t.index)
        .append
    end
    
    o.output.fragment.produce
    
    stripwells.length.times do |i|
      show {
        title "Load primers and template for stripwell #{stripwells[i].id}"
        table ingredients.from(i).to(i+11).choose([:well,:fwd,:rev,:template,:template_vol]).render
      }
      show {
        title "Load master mix and water for stripwell #{stripwells[i].id}"
        table ingredients.from(i).to(i+11).choose([:well,:mix_vol,:water_vol]).render
      }
    end
    
    data = show {
      title "Put stripwells in thermocycler"
      note "Set the annealing temperature to #{o.parameter.tanneal[0]}"
      get "number", var: "tc", label: "What thermocycler was used?", default: 1
    }

    o.threads.each do |t|
      t.data.tc = data[:tc]
    end
    
    o.input.all.release
    o.output.all.release

    return o.result     

  end

end
