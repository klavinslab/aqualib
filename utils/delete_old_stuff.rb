class Protocol

  def main

    another = true

    while another

      projects = find :project, {}
      sample_types = find(:sample_type,{})

      data = show {
        title "Choose project and sample type"
        select projects, var: "project", label: "Select Project Name"
        select sample_types.collect { |st| st.name }, var: "sample_type", label: "Select Sample Type"
      }

      project   = data[:project]
      sample_type = find(:sample_type,{name: data[:sample_type]})[0]

      data = show {
        title "Choose container type"
        select sample_type.object_types.collect { |ot| ot.name }, var: "object_type_name", label: "Select Object Type"
      }

      object_type_name = data[:object_type_name]

      items = find( :item, { sample: { project: project }, object_type: { name: data[:object_type_name] } } )

      if items.length > 0

        data = show {
          title "Choose items"
          select items.collect { |i| "#{i.id}: #{i.sample.name} at #{i.location}" }, var: "item_list", label: "Select Items", multiple: true
        }

        item_ids = data[:item_list].collect { |i| i.split(':')[0].to_i }

        show {
          title "Deleted!"
          note item_ids
        }

        item_ids.each { |iid| 
          i = find(:item,{id: iid})[0]
          touch i
          i.mark_as_deleted 
        }

      end 

      data = show {
        if items.length == 0
          title "No items"
          note "There are no items with container type #{object_type_name} associated with #{project}" 
        else
          title "More?"
        end
        select [ "Yes", "No" ], var: "more", label: "Delete more items?"
      }

      another = (data[:more] == "Yes")

    end

  end

end