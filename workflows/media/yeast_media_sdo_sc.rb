class Protocol

    def arguments
        {
            io_hash: {}
        }
    end

    def main
        io_hash = input[:io_hash]
        tasks = find(:task, {task_prototype: {name: "Yeast SDO or SC"} }).select { |t| %w[waiting ready].include? t.status }
        data = show {
            title "Choose which task to run"
            select tasks.collect { |t| t.name }, var: "choice", label: "Choose the task you want to run"
        }

        task_to_run = tasks.select { |t| t.name == data[:choice] }[0]
        media = task_to_run.simple_spec[:media_type]
        set_task_status(task_to_run, "done")
        media_name = find(:sample, id: media)[0].name
        media_ingredients = media_name.split(" -").drop(1)
        # show {
        # 	note media_name
        # 	note media_ingredients
        # 	note media_ingredients.pop(0)
        # }
        acid_bank = ["His", "Leu", "Ura", "Trp"]
        ingredients = []
        if(media_name == "SC")
            produced_media = produce new_sample "SC", of: "Media", as: "800 mL Bottle"
            present_acid = acid_bank

        elsif(media_name == "SDO")
            produced_media = produce new_sample "SDO", of: "Media", as: "800 mL Bottle"
            present_acid = []

        else
            produced_media = produce new_sample media_name, of: "Media", as: "800 mL Bottle"
            present_acid = acid_bank - media_ingredients
            present_acid.each do |i|
                if(i == "Leu")
                    ingredients += [find(:item,{object_type:{name:"Leucine Solution"}})[0]]
                elsif(i == "His")
                    ingredients += [find(:item,{object_type:{name:"Histidine Solution"}})[0]]
                elsif(i == "Trp")
                    ingredients += [find(:item,{object_type:{name:"Tryptophan Solution"}})[0]]
                else
                    ingredients += [find(:item,{object_type:{name:"Uracil Solution"}})[0]]
                end
            end           
        end
        
	produced_media.location = "Bench"
	io_hash = {type: "yeast"}.merge(io_hash)

        ingredients += [find(:item,{object_type: { name: "1 L Bottle"}})[0]]
        ingredients += [find(:item,{object_type:{name:"Adenine (Adenine hemisulfate)"}})[0]]
        ingredients += [find(:item,{object_type:{name:"Dextrose"}})[0]]
        ingredients += [find(:item,{object_type:{name:"Yeast Nitrogen Base Without Amino Acids"}})[0]]
        take ingredients, interactive: true

        show {
            title media_name
            note "Description: Makes 800 mL of #{media_name} media with 2% glucose and adenine supplement"
        }

        show {
            title "Get Bottle and Stir Bar"
            note "Retrieve one Glass Liter Bottle from the glassware rack and one Medium Magnetic Stir Bar from the dishwashing station, bring to weigh station. Put the stir bar in the bottle."
        }

        show {
            title "Weigh Chemicals"
            note "Weight out 5.36g nitrogen base, 1.12g of DO media, 16g of dextrose, .064g adenine sulfate and add to 1000 mL bottle"
        }

        show {
            title "Add Amino Acid"
            note "Add 8 mL of #{present_acid.join(", ")} solutions each to bottle"
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
            note "Label the bottle with '#{media_name}', 'Date', 'Your initials'"
        }
        release(ingredients + [produced_media], interactive: true)
        return {io_hash: io_hash}
    end
end
