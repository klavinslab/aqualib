
class Protocol
	
	def arguments
	    {
	    	io_hash: {}
	    }
	end
	
	def main
		io_hash = input[:io_hash]
		media = find(:item, id: (io_hash[:media]))[0]
		take [media], interactive: true
		if(io_hash[:type] == "bacteria")
			temp = 121
		elsif(io_hash[:type] == "yeast")
			temp = 110	
		else 
			raise ArgumentError, "Media is not valid"
		end
		
		show {
			title "Autoclave Media"
			note "Description: This protocol is for sterilizing the media used for #{io_hash[:type]}"
		}
		
		show {
			title "Tape Bottle"
			note "Stick autoclave tape on top of the bottle"
			warning "Make sure that the tape seals the cap to the bottle so that when you open the bottle you have to break the tape"
		}
		
		show {
			title "Autoclave"
			note "Check the water levels in the autoclave"
			note "Loosen cap and autoclave at #{temp}C for 15 minutes"
			note "5 beeps will signify that the autoclave is done"
		}
		
		release([media], interactive: true)
		return {io_hash: io_hash}
	end
end
