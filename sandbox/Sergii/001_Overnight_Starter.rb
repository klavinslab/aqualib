# This protocol creates overnight starter of E. coli culture, which is than used 
# for growing bacterial culture for protein overexpression.

# The differences from the common overnight starter protocol:
# 1. Media is only LB
# 2. Allow to set different antibiotic concentrations 
#    (I'm using 0.2 g/L instead of usual 0.1 g/L)
# 3. Culture can be made only from Petri dishes
# 4. Culture is inoculated with several (about 7) colonies.


class Protocol
  def main
    show {
      title "Hello World!"
    }
  end # main
end # Protocol
