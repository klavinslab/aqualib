#This protocol purifies gel slices into fragment stocks

needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

class Protocol


include Standard
include Cloning

def arguments
	{
	gelslice_ids: 

  def debug
    true
  end

	def main
	
	show{
		title "This protocol purfies gel slices int DNA fragment stocks."
	}
	end
end
