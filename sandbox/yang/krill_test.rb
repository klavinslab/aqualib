class Protocol
  
  def arguments
    {x: 1, y:"name"}
  end

  def main
    x = input[:x]
    y = input[:name]
    data = show {
    title "An input example"
    get "text", var: "y_data", label: "Enter a string", default: "Hello World"
    get "number", var: "z_data", label: "Enter a number", default: 555
    }
    y_data = data[:y]
    z_data = data[:z]
    show {
      title "Hello World!"
      note "y is #{y} and z is #{z}"
    }
  end
  
end
