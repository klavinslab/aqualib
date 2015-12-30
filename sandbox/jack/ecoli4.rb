class Protocol
  
  def arguments
    		{
    			io_hash: {}
    		}
	 end
  
  
  def main
  
    io_hash = input[:io_hash]
    flask2000 = find(:item, object_type: { name: "2000 mL flask"}) 
    lb_liquid = io_hash[:]
    overnight_flask = 
  
    show {
      title "Carefully pour warmed LB into 2000 mL flask"
      note "Tilt both bottles for sterile pouring"
    }
    
    show {
      title "Carefully pour overnight flask into 2000 mL flask with LB"
      note "Tilt both bottles for sterile pouring"
      note "Not necessary to pour out all foam"
    }
    
    show {
    
  
  end
end
