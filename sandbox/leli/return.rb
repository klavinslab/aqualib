class Protocol

  def main
  
    x = input
    
    data = show {
      title "An input/return example."
      get "text", var: "y", label:"Enter a string", default: "hi again"
    }
    
    y = data[:y]
    
    return x.merge y
  
  end

end
