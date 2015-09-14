class Protocol

  def main
  
    show {
      title "This is cool!"
      note "What am I doing"
      table[["A","C"], [1,3]]
      check "Check this!"
      select [ "A", "B", "C" ], var: "x", label: "Choose something", default: 1
    }
    
    show do
     title "You entered #{result[:x]}"
    end
    
    return {x:x, y:"That was fun"}
  end
  
end
