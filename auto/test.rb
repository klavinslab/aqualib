
class Protocol

  def debug
    true
  end

  def main

    o = op input

    # take o.inputs(:fwd).first_items, method: "boxes"
    # take o.inputs(:rev).first_items, method: "boxes"  
    # take o.inputs(:template).first_items, method: "boxes"

    show {
      title "#{o.name} Inputs"
      note o.input_names.join(", ")
      note o.inputs.collect { |name,ispec| "#{name}: #{ispec[:sample].name}"}
    }

  end

end
