
class Workflow

  def initialize operation
    @operation = operation
  end

  # INPUTS ###############################################################

  def inputs name
    Inv.new raw_input name
  end

  def raw_inputs
    @operation[:inputs]
  end

  def input_names
    @operation[:inputs].collect { |i| i[:name] }
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

    w = Workflow.new input

    # take w.inputs(:fwd).first_items, method: "boxes"
    # take w.inputs(:rev).first_items, method: "boxes"  
    # take w.inputs(:template).first_items, method: "boxes"

    show {
      title "Input names"
      note w.input_names.join(", ")
    }

  end

end
