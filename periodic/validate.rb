class Validator

  def check task

    # g = find(:group,name: task.spec[:group])
    return [ "Group: #{task.spec.inspect}" ]

  end


end