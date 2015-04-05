needs "aqualib/lib/standard"

class Validator

  include Standard

  def check task
    e = { x: [ "Task '#{task.name}' looks suspicious!", 
          "Could not validate task.", 
          "Honestly, I didn't try very hard." ] }
    return e
  end

end
