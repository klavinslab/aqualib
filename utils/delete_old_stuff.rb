class Protocol

	def main

		projects = find :project, {}
		sample_types = find(:sample_type,{})

		data = show {
			title "Choose project and sample type"
			select projects, var: "project", label: "Select Project Name"
			select sample_types.collect { |st| st.name }, var: "sample_type", label: "Select Sample Type"
        }

        project 	= data[:project]
        sample_type = find(:sample_type,{name: data[:sample_type]})[0]

		data = show {
			title "Choose container type"
			select sample_type.object_types.collect { |ot| ot.name }, var: "object_type", label: "Select Object Type"
		}

		object_type_name = data[:object_type]

		items = find( :item, { sample: { project: project }, object_type: { name: data[:object_type_name] })

	end

end