class Protocol
  
  def arguments
    		{
    			io_hash: {}
    		}
	 end
  
  
  def main
  
    io_hash = input[:io_hash]
    flask2000 = find(:item, object_type: { name: "2000 mL Flask"})[0]
    lb_liquid = find(:item, id: (io_hash[:new_lb_liquid]))[0]
    overnight_flask = find(:item, id: (io_hash[:dh5alpha]))[0]
    
    take [flask2000, lb_liquid, overnight_flask], interactive: true
    over_night_flask.location = "Dishwashing Station"
    lb_liquid.location = "Dishwashing Station"
    flask2000.location = "37 degree shaker"
    
    show {
      title "Carefully pour warmed LB into 2000 mL flask"
      note "Tilt both bottles for sterile pouring"
    }
    
    show {
      title "Carefully pour overnight flask into 2000 mL flask with LB"
      note "Tilt both bottles for sterile pouring"
      note "Not necessary to pour out all foam"
    }
    
    release([flask2000, lb_liquid, overnight_flask], interactive: true)
    
    show {
    	title "Prepare for spins"
    	note "Set large centrifuge to 4 C"
    	note "Move (4) 225 mL centrifuge tubes to freezer"
    	note "Move 500 mL 10% glycerol and 1 L sterile DI water to fridge"
    }
    
    io_hash = { dh5alpha_new: flask2000.id }.merge(io_hash)
    return { io_hash: io_hash }
  
  end
end
