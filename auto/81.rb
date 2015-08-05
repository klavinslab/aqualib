
class Protocol

  def debug
    true
  end

  def main

    o.input.all.take

    stripwells = o.output(:fragment).new_collections

    stripwells.slots do |index,slot|
      slot.sample = o.output(:fragment).samples[index]
      slot.ingredients[:fwd] = { id: i.input(:fwd).item.id, volume: 1 }
      slot.ingredients[:rev] = { id: i.input(:rev).item.id, volume: 1 }
      slot.ingredients[:template] = { id: i.input(:template).item.id, volume: 1 }
      slot.ingredients[:master_mix] = { volume: 1 }
      slot.ingredients[:water] = { volume: 1 }
    end

    stripwells.produce

    stripwells.length.times do |i|
      show {
        title "Load primers and template for stripwell #{stripwells[i].id}"
        table stripwells.table i, id: "Stripwell", row: "Well", fwd:, :rev, :template 
      }
      show {
        title "Load master mix and water for stripwell #{stripwells[i].id}"
        table stripwells.table i, id: "Stripwell", row: "Well", :master_mix, :water 
      }
    end

    use o.parameter(:annealing_temperature)

    o.data(:tc) = (show {
      title "Put stripwells in thermocycler"
      note "Set the annealing temperature to #{o.parameter(:annealing_temperature)}"
      get "number", var: "tc", label: "What thermocycler was used?", default: 1
    })[:tc]

    o.input.all.release
    stripwells.release

    return o.result     

  end

end
