class Protocol

  def debug
    true
  end

  def main

    o = op input
    o.input.all.take
    stripwells = o.output.fragment.new_collections
    
    # collection wise
    stripwells.slots do |index,slot|
      if index < o.output.fragment.samples.length 
        o.output.fragment.associate index, slot
        slot.ingredients[:fwd]        = { id: o.input.fwd.items[index], volume: 1 }
        slot.ingredients[:rev]        = { id: o.input.rev.items[index], volume: 2 }
        slot.ingredients[:template]   = { id: o.input.template.items[index], volume: 3 }
        slot.ingredients[:master_mix] = { volume: 4 }
        slot.ingredients[:water]      = { volume: 5 }
      end
    end

    # threadwise
    # (o.threads.reject { |t| t[:error] }).each do |thread|
    #   stripwells.slot[thread.index] = thread[:fragment][:sample]
    #   stripwells.slot[thread.index].ingredients[:rev] = { id: thread[:rev][:item], volume: 1 }
    # end

    # bothwise
    # o.threads.zip(stripwells, include_errors: false).each do |thread, slot| 
    #   slot.ingredients[:rev] = { id: thread[:rev][:item], volume: 1} 
    # end
    
    o.output.fragment.produce
    
    stripwells.length.times do |i|
      show {
        title "Load primers and template for stripwell #{stripwells[i].id}"
        table stripwells.table(i, id: "Stripwell", col: "Well", fwd: "Forward primer", rev: "Reverse Primer", template: "Template")
      }
      show {
        title "Load master mix and water for stripwell #{stripwells[i].id}"
        table stripwells.table(i, id: "Stripwell", col: "Well", master_mix: "Master Mix", water: "Water")
      }
    end
    
    data = show {
      title "Put stripwells in thermocycler"
      note "Set the annealing temperature to #{o.parameter.annealing_temperature[0]}"
      get "number", var: "tc", label: "What thermocycler was used?", default: 1
    }
    
    o.data.tc.get.each do |d|
      puts "setting d = #{d} to data[:tc] = #{data[:tc]}"
      d = data[:tc]
    end
    
    o.input.all.release
    o.output.all.release
    return o.result     

  end

end
