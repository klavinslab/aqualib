class Protocol
  def main
    show {
      title "Hello World!" 
      (1..10).each { |i|
        get "number",  var: "g#{i}"
      }
    }
    show {
      title "Thanks :-)"
    }
  end
end
