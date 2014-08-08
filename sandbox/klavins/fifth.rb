
needs "aqualib/sandbox/klavins/test_lib"

class Protocol

  include A

  def main

    t = Thing.new 0
    y f 2
   
    show {
            title "It's working"
            note t.get
            note y
    }

  end

end
