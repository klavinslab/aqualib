class Protocol

	def main

		projects = find(:project)

		show {
			title "Choose a project"
			select projects, var: "project", label: "Select Project Name"
		}

	end

end