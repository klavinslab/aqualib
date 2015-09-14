class Protocol

  def main
  
    result = show {
      title "Hello Bootcamp!"
      note "Hello world"
      table [["A","B"],[1,2]]
      check "Check this"
      select ["A","B","C"], var: "x", label: "Choose something", default: 1
    }
    
    show do 
      title "You entered #{x}"
    end
  
    return {x: x, y: "that was fun"}
  
  end
  
end
