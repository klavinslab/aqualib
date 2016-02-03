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
    (61784..61811).each do |i|
      item = Item.find(i)
      item.object_type_id = 478
      item.location = "Gel drawer"
      item.save
    end
  end

end
