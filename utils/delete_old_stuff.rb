class Protocol

	def main

		projects = find :project, {}
		sample_types = find(:sample_type,{})

		data = show {
			title "Choose item types to delete"
			select projects, var: "project", label: "Select Project Name"
			select sample_types.collect { |st| st.name }, var: "sample_type", label: "Select Sample Type"
        }


	end

end