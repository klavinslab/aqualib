class Protocol

  def arguments
    {
      type: "Daily"
    }
  end

  def main

    type = input[:type]

    tasks = find(:task,{task_prototype: {name: type},status: "ready"})

    if tasks.length == 0

      show {
        title "All %{type} tasks have been completed or are in progress."
        note "Thanks for checking!"
      }

    else

      while tasks.length > 0

        data = show {
          title "Available #{type} Tasks"
          note "The following tasks have not been completed today."
          select tasks.collect { |t| t.name }, var: "choice", label: "Choose a task", default: 1
        }

        task = (tasks.select { |t| t.name == data[:choice] }).first

        task.status = "working"
        task.save

        spec = task.spec 

        data = show {
          title task.name
          spec[:notes].map    { |n| note n }
          spec[:checks].map   { |c| check c }
          spec[:warnings].map { |w| warning w }
          spec[:images].map   { |i| image i }
          select [ "Yes", "No" ], var: "done", label: "Did you complete the task?", default: 1
        }

      end

    end

  end

end



# if length(tasks) == 0

#   step
#     description: "All %{type} tasks have been completed or are in progress."
#     note: "Thanks for checking!"
#   end

# else

#   while length(tasks) > 0

#     step
#       description: "Available %{type} Tasks"
#       note: "The following tasks have not been completed today."
#       getdata
# 	name: string, "Choose a task", ha_select(tasks,:name)
#       end
#     end

#     task = ha_get(tasks,:name,name)

#     set_task_status(task,"working")

#     step
#       description: task[:name]
#       foreach n in task[:specification][:notes]
#         note: n
#       end
#       foreach c in task[:specification][:checks]
#         check: c
#       end 
#       foreach w in task[:specification][:warnings]
#         warning: w
#       end
#       foreach i in task[:specification][:images]
#         image: i
#       end
#       getdata
#         done: string, "Did you complete the task?", ["Yes", "No"]
#       end
#     end

#     if done == "Yes"

#       set_task_status(task,"done")

#       step
#         description: "Thank you!"
#         note: "Aquarium has made a note of your efforts."
#       end

#       log
#         TASK: { task: task }
#       end

#     else

#       set_task_status(task,"ready")

#     end

#     if done == "No" || length(tasks) > 1

#       step
#         description: "Another task?"
#         getdata
#           more: string, "Do you have time to do another %{type} task?", [ "Yes", "No" ]
#         end
#       end
     
#       if more == "Yes"
#         tasks = tasks(type,"ready")
#       else
#         tasks = []
#       end

#     else

#       step
#         description: "Done with daily tasks."
#         note: "There are no more %{type} tasks."
#       end

#       tasks = []

#     end

#   end

# end
