class Validator

  def check task

    g = find(:group,name: task.spec[:group])
    return [ "Length is #{g.length}"]

  end


end