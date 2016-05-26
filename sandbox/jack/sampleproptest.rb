class Protocol
	
	def arguments
    		{
    		}
	 end
	
	def main
		test_samp = find(:item, { sample: { name: "SSJ128"}, object_type: { name: "Plasmid Stock" }})[0]
		test_samp.sample.properties.each do |key, value|
    			show {
    				note "#{key}:#{value}"
    			}
		end
		show {
			note test_samp.sample.properties["Bacterial Marker".to_sym]
		}
	end
end
