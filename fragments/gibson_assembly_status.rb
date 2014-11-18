needs "aqualib/lib/cloning"

class Protocol

	include Cloning

	def main

	  gas = gibson_assembly_status

	  show {

	  	title "Gibson Assemblies in the Pipeline"

	  	note "Gibson Assemblies"
	  	table [ 
	  		[ "Under Construction", gas[:assemblies][:under_construction].to_s ], 
			[ "Waiting for Ingredients", gas[:assemblies][:waiting_for_ingredients].to_s ],
	  	 	[ "Ready to Build", gas[:assemblies][:ready_to_build].to_s ],		
	  		[ "Done on a plate", gas[:assemblies][:on_plate].to_s ]
	  	]	
	  	
	  	note "Fragments"
	  	table [
	  		[ "Ready To Use",  gas[:fragments][:ready_to_use].to_s ],
	  	 	[ "Ready To Build",  gas[:fragments][:ready_to_build].to_s ],
	  	 	[ "Not Ready To Build", gas[:fragments][:not_ready_to_build].to_s ]
	  	]	
	  	  	
	  }

	  return gas

	end

end
