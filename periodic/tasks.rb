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

        if data[:done] == "Yes"

          task.status = "done"
          task.save
          show {
            title "Thank you!"
            note "Aquarium has made a note of your efforts"
          }

        else

          task.status = "ready"
          task.save

        end

        if data[:done] == "No" || tasks.length > 1

          show {
            title "Another task?"
            select ["Yes","No"], var: "choice", label: "Do you have time for another #{type} task?", default: 1
          }

          if more == "Yes"
            tasks = find(:task,{task_prototype: {name: type},status: "ready"})
          else
            tasks = []
          end

        else

          show {
            title "Done with daily tasks."
            note "There are no more #{type} tasks."
          }

          tasks = []

        end

      end

    end

  end

end



# end
