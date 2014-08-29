
class Protocol

	def main

		# This protocol determines the set of all fragments that need to be made
		# for the current list of Gibson Assemblies. 

		tasks = find(:task,{task_prototype: { name: "Gibson Assembly" }})
		fragments = (tasks.collect { |t| t.spec }).flatten

		show {
			title "Tasks"
			table tasks.collect { |t| [ t.id, t.name ] }
		}

		show {
			title "Fragments"
			note fragments.to_s
		}

		#show {
		#	title "Fragments Required for Current Gibson Assmebly Tasks"
		#	table tasks.collect { |t| [ t[:id], t[:fragments] }
		#}

	end

end