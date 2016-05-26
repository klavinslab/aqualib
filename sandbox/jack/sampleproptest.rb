class Protocol
	
	def arguments
    		{
    		}
	 end
	
	def main
		test_samp = find(:item, { sample: { name: "SSJ128"}, object_type: { name: "Plasmid Stock" }})[0]
		show {
			note test_samp.sample.properties
		}
	end
end
