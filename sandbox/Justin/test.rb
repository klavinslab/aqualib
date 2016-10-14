needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
  def main
    to_be_added = [16204]
    to_be_added.each do |i|
      k = produce new_sample "new_enzyme", of: "Enzyme", as: "Enzyme Stock"
#       j = produce new_sample "pLAB1",       of: "Plasmid",      as: "Plasmid Stock"
#       j = produce new_sample sample[:name], of: “Enzyme”, as: “Enzyme Stock”
    end
  end
end
