
class Protocol

  def debug
    true
  end

  def main

    t = Time.now
    puts "  #{((Time.now-t).seconds*1000).to_i}: A"
    o = op input
    puts "  #{((Time.now-t).seconds*1000).to_i}: B"
    o.input.all.take
    puts "  #{((Time.now-t).seconds*1000).to_i}: C"
    stripwells = o.output.fragment.new_collections
    puts "  #{((Time.now-t).seconds*1000).to_i}: D"
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
    puts "  #{((Time.now-t).seconds*1000).to_i}: E"
    o.output.fragment.produce
    puts "  #{((Time.now-t).seconds*1000).to_i}: F"
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
    puts "  #{((Time.now-t).seconds*1000).to_i}: H"
    data = show {
      title "Put stripwells in thermocycler"
      note "Set the annealing temperature to #{o.parameter.annealing_temperature[0]}"
      get "number", var: "tc", label: "What thermocycler was used?", default: 1
    }
    puts "  #{((Time.now-t).seconds*1000).to_i}: I"
    o.data.tc.get.each do |d|
      d = data[:tc]
    end
    puts "  #{((Time.now-t).seconds*1000).to_i}: J"
    o.input.all.release
    puts "  #{((Time.now-t).seconds*1000).to_i}: K"
    o.output.all.release
    puts "  #{((Time.now-t).seconds*1000).to_i}: L"
    return o.result     

  end

end
