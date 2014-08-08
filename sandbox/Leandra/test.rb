class Protocol
  def main
    data = show {
      title "Hello World!" 
    }
    show {
      title "Thanks :-)"
      note data["g3".to_sym]
    }
  end
end
