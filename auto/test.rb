
class Protocol

  def debug
    true
  end

  def main

    o = thing input

    # take o.inputs(:fwd).first_items, method: "boxes"
    # take o.inputs(:rev).first_items, method: "boxes"  
    # take o.inputs(:template).first_items, method: "boxes"

    show {
      note "Test"
      #title "#{o.name} Inputs"
      #note o.input_names.join(", ")
      #note "names = #{o.inputs.collect { |i| i[:sample] ? i[:sample].name : "-" }}"
    }

  end

end
