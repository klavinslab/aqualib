#
# This protocol used to crash the Krill server, but now it won't.
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

