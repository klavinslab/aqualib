needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
  
  include Standard
  include Cloning
  
  def debug
    false
  end
  
  def arguments
    { x:1, y: "name" }
  end
  
  
  
  def main
   
    x = input[:x]
    y = input[:name]

    show {
        title "Arguments"
        note "x = #{x}, y = #{y}"
      }
  
  end
  
end
