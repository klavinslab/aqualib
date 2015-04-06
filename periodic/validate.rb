class Validator

  def check task

    g = Group.find_by_name(task.spec[:group])
    return [ "Group: '#{task.spec[:group]}', length: #{g.length}" ]

  end


end