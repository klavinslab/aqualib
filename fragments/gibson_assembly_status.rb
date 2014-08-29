needs "aqualib/lib/cloning"

class Protocol

	include Cloning

	def main

	  gas = gibson_assembly_status

	  show {
	  	title "Status"
	  	note gas.to_s
	  }

	  return gas

	end

end
