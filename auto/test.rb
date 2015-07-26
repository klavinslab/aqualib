class InvArray

  include Enumerable

  def initialize ispecs
    @ispecs = Array.new ispecs
    @ispecs.each do |i| 
      i[:sample_number] = i[:sample]
      i[:sample] = Sample.find(i[:sample_number])
    end
    @ispecs
  end

  def each &block
    if block_given?
      @ispecs.each &block
    else
      @ispecs.each { |i| yield i }
    end
  end

end

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

  def inputs
    @inv_array ||= InvArray(@spec[:inptus])
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
      # note "names = #{i.inputs.collect { |i| i[:sample].name }}"
    }

  end

end
