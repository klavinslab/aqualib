needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol
  include Stanard
  include Cloning
  
  def arguments
    {
      samples_ids: [5913, 5914]
    }
  end
  
  def main
    {
    }
  end
end
