needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol

  include Standard
  include Cloning

  def arguments
    {
      fragment_ids: []
    }
  end
  
  def main
    input[:fragment_ids].each do |fragment_id|
      fragment = find(:sample, id: fragment_id)[0]
      fragment.user_id = 5
      fragment.save
    end
  end
  
end
