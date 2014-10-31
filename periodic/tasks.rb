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
        title "All #{type} tasks have been completed or are in progress."
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
        set_task_status( task, "working" )

        data = show {
          title task.name
          task.spec[:notes].map    { |n| note n }
          task.spec[:checks].map   { |c| check c }
          task.spec[:warnings].map { |w| warning w }
          task.spec[:images].map   { |i| image i }
          select [ "Yes", "No" ], var: "done", label: "Did you complete the task?", default: 1
        }

        set_task_status( task, data[:done] == "Yes" ? "done" : "ready" )

        if data[:done] == "No" || tasks.length > 1

          data = show {
            title "Thank you!"
            note "Aquarium has made a note of your efforts"
            select ["Yes","No"], var: "choice", label: "Do you have time for another #{type} task?", default: 1
          }

          if data[:choice] == "Yes"
            tasks = find(:task,{task_prototype: {name: type},status: "ready"})
          else
            tasks = []
          end

        else

          show {
            title "Thank you!"
            note "Done with daily tasks."
            note "There are no more #{type} tasks."
          }

          tasks = []

        end

      end

    end

  end

end

