class Protocol

  def main

    (1..5).each do |i|

      show {
        title "Step #{i}"
        log i: i, methods: self.methods # log some arbitrary data
      }

    end

    return { message: "Thanks for testing the log method." }

  end

end