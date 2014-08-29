needs "aqualib/lib/cloning"

class Protocol

	include Cloning

	def main

	  gas = gibson_assembly_status

	  show {
	  	title "Gibson Assemblies in the Pipeline"
	  	note "Under Construction: #{gas[:assemblies][:under_construction]}"
		note "Waiting for Ingredients: #{gas[:assemblies][:waiting_for_ingredients]}"
	  	note "Ready to Build: #{gas[:assemblies][:ready_to_build]}"		
	  	note "Out for Sequencing: #{gas[:assemblies][:out_for_sequencing]}"		
	  	separator
	  	note "Fragments Ready To Use: #{gas[:fragments][:ready_to_use]}"
	  	note "Fragments Ready To Build: #{gas[:fragments][:ready_to_build]}"
	  	note "Fragments Not Ready To Build: #{gas[:fragments][:not_ready_to_build]}"	  	
	  }

	  return gas

	end

end
