class Validator

  def check task

    g = Group.find_by_name(task.spec[:group])
    return [ "Could not find group '#{task.spec[:group]}'"] unless g

    true

  end


end