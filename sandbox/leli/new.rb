#hi
class Protocol
  def main
    data = show {
      title "Hello World!"
      title "An input example."
      get "text", var: "y", label:"Enter a string", default: "hi again"
    }
    
    y = data[:y]
  end
end
