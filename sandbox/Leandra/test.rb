class Protocol
  def main
    data = show {
      title "Hello World!" 
      (1..10).each { |i|
        get "number",  var: "g#{i}"
      }
    }
    show {
      title "Thanks :-)"
      note data["g3".to_sym]
    }
  end
end
