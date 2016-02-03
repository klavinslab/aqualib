needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
    }
  end

  def main
    (61812..61820).each do |i|
      item = Item.find(i)
      item.location = "Gel drawer"
      item.save
    end
  end

end
