class Protocol
  def main
    data = show {
  title "An input example"
  get "text", var: "y", label: "Enter a string", default: "Hello World"
  get "number", var: "z", label: "Enter a number", default: 555
    }
   y = data[:y]
   z = data[:z]
    show {
      title "Hello World!"
      note "y is #{y} and z is #{z}"
    }
  end
end
