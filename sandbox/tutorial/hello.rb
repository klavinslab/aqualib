class Protocol
  def main
    show {
      title "Hello World!" 
      (1..10).each { |i|
        note "i = #{i}"
      }
    }
    show {
      title "Thanks :-)"
    }
  end
end
