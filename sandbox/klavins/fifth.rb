
needs "Krill/test_lib"

class Protocol

  include A

  def main

    t = Thing.new 0
   
    show(
            { title: "It's working" },
            { note: t.get },
            { note: (f 2) }
    )

  end

end
