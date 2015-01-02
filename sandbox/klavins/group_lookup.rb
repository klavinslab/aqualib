class Protocol

  def main

    name = "technicians"
    group = Group.find_by_name(name)

    if group
      gid = group.id
    else
      raise "Group #{name} not found"
    end

    show do
      title "Hello"
      note "Group #{name} has id #{gid}"
    end

  end

end