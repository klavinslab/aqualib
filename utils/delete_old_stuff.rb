class Protocol

	def main

		projects = find :project, {}

		project = (show {
			title "Choose a project"
			select projects, var: "project", label: "Select Project Name"
		})[:project]

		sample_types = find(:sample_type,{})

		sample_type = (show {
			title "Choose a sample type"
			select sample_types, var: "sample_type", label: "Select Sample Type"
		})[:sample_type]


	end

end