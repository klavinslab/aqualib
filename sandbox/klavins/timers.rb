class Protocol

  def main

    show {
      title "Default Timer"
      timer
    }

    show {
      title "Initial Time Specified"
      timer initial: { hours: 0, minutes: 0, seconds: 20 }
    }

    show { 
      title "Count Up"
      timer final: { hours: 0, minutes: 0, seconds: 10 }, direction: "up"
    }

  end

end