class Protocol
	
	def arguments
    		{
    			io_hash: {}
    		}
	 end
	
  def main
		io_hash = input[:io_hash]
		media = find(:item, id: (io_hash[:media]))[0]
		if(media.name.include? "LB" || media.name.include? "TB")
		  
