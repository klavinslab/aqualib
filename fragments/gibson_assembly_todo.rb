
class Protocol

	def main

		show {
			title "Gibson Todo List"
			note "This protocol determines the set of all fragments that need to be made
                  for the current list of Gibson Assemblies."
        }

		tasks = find(:task,{task_prototype: { name: "Gibson Assembly" }})
		tasks.each { |t| t[:target] = Sample.find(t.simple_spec[:target]) }

		show {
			title "Tasks"
			table(
			  [ [ "Task ID", "Name", "Status", "Target ID", "Target Name" ] ]
			  .concat tasks.collect { |t| [ t.id, t.name, t.status, t[:target].id, t[:target].name ] }
			)
		}

		fragments = (tasks.collect { |t| t.simple_spec[:fragments] }).flatten

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