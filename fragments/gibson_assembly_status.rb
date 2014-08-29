needs "aqualib/lib/cloning"

class Protocol

	include Cloning

	def main

	  gas = gibson_assembly_status

	  show {
	  	title "Gibson Assemblies in the Pipeline"
	  	table [ 
	  		[ "Under Construction", gas[:assemblies][:under_construction].to_s ], 
			[ "Waiting for Ingredients", gas[:assemblies][:waiting_for_ingredients].to_s ],
	  	 	[ "Ready to Build", gas[:assemblies][:ready_to_build].to_s ],		
	  		[ "Out for Sequencing", gas[:assemblies][:out_for_sequencing].to_s ]
	  	]	
	  	
	  	table [
	  		[ "Fragments Ready To Use",  gas[:fragments][:ready_to_use].to_s ],
	  	 	[ "Fragments Ready To Build",  gas[:fragments][:ready_to_build].to_s ],
	  	 	[ "Fragments Not Ready To Build", gas[:fragments][:not_ready_to_build].to_s ]
	  	]	  	
	  }

	  return gas

	end

end
