class Protocol

  def debug
    true
  end

  def main

    puts "Starting PCR"

    o = op input
    o.input.all.take
    stripwells = o.output.fragment.new_collections
    
    # stripwells.slots do |index,slot|
    #   if index < o.output.fragment.length 
    #     o.output.fragment.associate index, slot
    #     slot.ingredients[:fwd]        = { id: o.input.fwd.item_ids[index], volume: 1 }
    #     slot.ingredients[:rev]        = { id: o.input.rev.item_ids[index], volume: 2 }
    #     slot.ingredients[:template]   = { id: o.input.template.item_ids[index], volume: 3 }
    #     slot.ingredients[:master_mix] = { volume: 4 }
    #     slot.ingredients[:water]      = { volume: 5 }
    #   end
    # end

    show do
      o.threads.each do |thread|
        note "#{thread.inputs.collect { |i| i[:name] }}"
      end
    end

    # bothwise
    # o.threads.spread(stripwells).each do |thread, slot| 
    #  thread.output.fragment.associate slot
    # end
    
    o.output.fragment.produce
    
    stripwells.length.times do |i|
      show {
        title "Load primers and template for stripwell #{stripwells[i].id}"
        note "Table #{i} here"
      }
      show {
        title "Load master mix and water for stripwell #{stripwells[i].id}"
        table "Table #{i} here"
      }
    end
    
    data = show {
      title "Put stripwells in thermocycler"
      note "Set the annealing temperature to #{o.parameter.annealing_temperature[0]}"
      get "number", var: "tc", label: "What thermocycler was used?", default: 1
    }

    o.data.tc.get[0][:instantiation].length.times do |i|
      o.data.tc.get[0][:instantiation][i] = data[:tc]
    end
    
    o.input.all.release
    o.output.all.release
    return o.result     

  end

end
