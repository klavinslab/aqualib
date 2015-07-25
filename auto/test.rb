class Op

  def initialize spec
    @spec = spec
  end

  # INPUTS ###############################################################

  def name
    @spec[:name]
  end

  def input_names
    @spec[:inputs].collect { |i| i[:name] }
  end

  def raw_input name
    match = raw_inputs.select { |i| i[:name] == name }
    raise "Could not find input named #{name}" unless match.length != 0
    match.first
  end

end

class Protocol

  def debug
    true
  end

  def main

    o = Op.new input

    # take o.inputs(:fwd).first_items, method: "boxes"
    # take o.inputs(:rev).first_items, method: "boxes"  
    # take o.inputs(:template).first_items, method: "boxes"

    show {
      title "#{o.name} Inputs"
      note o.input_names.join(", ")
    }

  end

end
