
class Protocol
	
	def arguments
	    {
	    	io_hash: {}
	    }
	end
	
	def main
		io_hash = input[:io_hash]
		all_media = Array.new
		io_hash[:total_media].each do |i|
			all_media.push(find(:item, id: i)[0])
		end
		take all_media, interactive: true
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
			note "Stick autoclave tape on top of the bottle(s)"
			warning "Make sure that the tape seals the cap(s) to the bottle(s) so that when you open the bottle(s) you have to break the tape"
		}
		
		show {
			title "Autoclave"
			note "Check the water levels in the autoclave"
			note "Loosen cap(s) and autoclave at #{temp}C for 15 minutes"
			note "5 beeps will signify that the autoclave is done"
		}
		
		release(all_media, interactive: true)
		return {io_hash: io_hash}
	end
end
