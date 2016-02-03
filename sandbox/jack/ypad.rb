class Protocol

    def arguments
        {
            io_hash: {}
        } 
    end

    def main
        io_hash = input[:io_hash]
        tasks = find(:task, { task_prototype: { name: "YPAD" } }).select { |t| %w[waiting ready].include? t.status }

        data = show {
            title "Choose which task to run"
            select tasks.collect { |t| t.name }, var: "choice", label: "Choose the task you want to run"
        }

        task_to_run = tasks.select { |t| t.name == data[:choice] }[0]
        set_task_status(task_to_run, "done")
        media = task_to_run.simple_spec[:media_type]
        if(media == 11767)
            adenine = find(:item, { object_type: { name: "Adenine (Adenine hemisulfate)" } } )[0] 
            dextrose = find(:item, { object_type: { name: "Dextrose" } } )[0] 
            bacto = find(:item, { object_type: { name: "Bacto Yeast Extract" } } )[0] 
            tryp = find(:item, { object_type: { name: "Bacto Tryptone" } } )[0]
            if(task_to_run.simple_spec[:media_container] == "800 mL Bottle")
                bottle = find(:item, { object_type: { name: "1 L Bottle" } } )[0]
            else
                raise ArgumentError, "Chosen container is not valid"
            end
        else
            raise ArgumentError, "Chosen media is not valid"
        end
        
        take [adenine, dextrose, bacto, tryp, bottle], interactive: true

        show {
          title "Make YPAD Media"
          note "Description: Make 800 mL of yeast extract-tryptone-dextrose medium + adenine (YPAD)"
        }

        show {
          title "Weigh Chemicals"
          note "Weight out 8g yeast extract, 16g tryptone, 16g dextrose, .064g adenine sulfate and add to 1000 mL bottle"
        }

        show {
          title "Measure Water"
          note "Take the bottle to the DI water carboy and add water up to the 800 mL mark"
        }

        show {
          title "Mix solution"
          note "Shake until most of the powder is dissolved."
          note "It is ok if a small amount of powder is not dissolved because the autoclave will dissolve it"
        }

        show {
          title "Cap Bottle"
          note "Place cap on bottle loosely"
        }

        show {
          title "Label Bottle"
          note "Label the bottle with 'YPAD', 'Date', Your initials'"
        }

        release([bottle])
        release([adenine, dextrose, bacto, tryp], interactive: true

        return {io_hash: io_hash}


    end

end
