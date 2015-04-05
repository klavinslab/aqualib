needs "aqualib/lib/cloning"

class Validator

  include Cloning

  def check task
    e = [ "Task '#{task.name}' looks suspicious!", 
          "Could not validate task.", 
          "Honestly, I didn't try very hard." ]
    return e
  end

end
