
class Timer

  def initialize
    @t = Time.now
    @i = 1
  end

  def click
    puts "#{@i}: #{((Time.now-@t).seconds*1000).to_i} ms"
    @t = Time.now
    @i += 1
  end

end

class Protocol

  def debug
    true
  end

  def main

    t = Timer.new
    o = op input
    t.click
    o.input.all.take
    t.click
    stripwells = o.output.fragment.new_collections
    t.click
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
    t.click
    o.output.fragment.produce
    t.click
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
    t.click
    data = show {
      title "Put stripwells in thermocycler"
      note "Set the annealing temperature to #{o.parameter.annealing_temperature[0]}"
      get "number", var: "tc", label: "What thermocycler was used?", default: 1
    }
    t.click
    o.data.tc.get.each do |d|
      d = data[:tc]
    end
    t.click
    o.input.all.release
    t.click
    o.output.all.release
    t.click
    return o.result     

  end

end
