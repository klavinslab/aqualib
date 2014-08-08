class Protocol
  
  def arguments
    {x: 1379, y:"name"}
  end

  def main
    x = input[:x]
    y = input[:name]
    plasmid_x1 = find(:item, id: 123)
    take plasmid_x1
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
