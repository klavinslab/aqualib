
class Protocol

	def main

		# This protocol determines the set of all fragments that need to be made
		# for the current list of Gibson Assemblies. 

		tasks = find(:task,{task_prototype: { name: "Gibson Assembly" }}).collect { |t| 
        	{
        		id: t.id,
        		fragments: t.spec[:fragments].collect { |fid| find(:sample, { id: fid } ) }
        	}
        }

		show {
			title "Fragments Required for Current Gibson Assmebly Tasks"
			table tasks.collect { |t| [ t[:id], t[:fragments].collect { |f| f.id } ] }
		}

	end

end