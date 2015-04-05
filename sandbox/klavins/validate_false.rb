class Validator

  def check task
    e = [ "Task #{task.name} is suspicious to me.", 
          "Could not validate task.", 
          "Honestly, I didn't try very hard." ]
    return e
  end

end
