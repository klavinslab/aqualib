class Validator

  def check task

    g = find(:group,name: task.spec[:group])
    return [ "Group: '#{task.spec[:group]}', length: #{g.length}" ]

  end


end