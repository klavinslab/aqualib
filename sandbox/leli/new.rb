#hi
class Protocol
  def main
    
    #m = [
    #  [ "A", "Very", "Nice", { content: "Table", style: { color: "#f00"}}],
    #  [{content: 1, check: true},2,3,4]
    #]
    
    m = [ ["A","B"], [1,2] ]
    
    data = show {
      title "Hello World!"
      title "An input example."
      table m
      get "text", var: "y", label:"Enter a string", default: "hi again"
    }
    
    y = data[:y]
  end
end
