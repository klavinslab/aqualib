#
# This protocol used to crash the Krill server, but now it won't because
# Krill now has a limit to how many shows can be requested before stopping.
#

class Protocol

  def debug
    true
  end

  def main

    while true

      show {
        title "Debug loop"
      }

    end

  end

end

