needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#doc https://github.com/klavinslab/aquarium/blob/master/doc/Krill.md

class Protocol

    include Standard
    include Cloning

    def arguments
        {
            duration: "6h",
            intervals: "3min",
            how_many_individual_cells: 5,
            how_many_group_3or4_cells: 3,
            note_about_choosing_cells: "Good luck",
            FP_channels: "GFP,mCherry,YFP",
            overnight_id:0,
            debug_mode: "No"
        }
    end

    def main
        if input[:debug_mode].downcase == "yes"
            def debug
                true
            end
        end

        duration = input[:duration]
        intervals = input[:intervals]
        channels = input[:FP_channels]
        overnight_id =input[:overnight_id]
        how_many_individual_cells= input[:how_many_individual_cells]
        how_many_group_3or4_cells=input[:how_many_group_3or4_cells]
        note_about_choosing_cells=input[:note_about_choosing_cells]

        #use take items
        #take items, interactive: true



        show {
          title "NIS Element configuration"
          note "We will configure the software to perform the acquisition."

        }

        #
        show {
            title "NIS Element: live view"
            note "Go to the computer, start NIS Element."
            note "In the menu, choose 'Calibration > Optical configuration'. Then click 'Restore' and choose within Dropbox/Microscope/yeast_optical_configuration.xml"
            note "Click on the play buttom and then Auto Scale LUTs whithin the live view."
            note "Make sure you can also see Ti-pad and ND_Acquisition. If not, right click in the empty space next to the live view and select them."
            note "In the Ti-pad, you might need to click on the red/green button to turn on the light. It should be at 4M."
            image "live_view"
        }
        show {
            title "Load experiment and configure time"
            note "In ND Acquisition, choose 'load' with Dropbox/Microscope/FP_Yeast.xml"
            note "Start with the time tab."
            note " Configure it so that the duration is #{duration} and the intervals is #{intervals}."
            note "In advance setting, verify that Autofocus has 'step in range' selected, it will adjust Z so that the cells remain in focus overtime."
            image "nd_acquisition_time"
        }
        show {
            title "Configure lambda"
            note "In ND Acquisition, choose the lambda tab."
            note "ALWAYS leave brightfield on."
            note "The user wants the following channels: #{channels}. Select those accordingly. (If it is empty or None, leave only brightfield checked.)"
            note "Again, make sure brightfield is selected, we always need at least that one!"
        }

        show {
            title "Configure XY"
            note "In ND Acquisition, choose the XY tab."
            note "Now you are going to look for cells to image and you will record their positions!"
            note "Play with both the controllers Z and XY to find yeast cells."
            warning "If the controllers do not work: got to Devices, Manage Devices. Select NikonTi, click connect. Select RFA, click connect. If it is still not working, restart both the microscope and the computer, and reconnect devices."
            note "Z has a small sweet spot. It can be tricky to find. The oil should spread touching the bottom of the dish. But you should not go too high with Z as it will push the dish out of its mount."
            note "Look for #{how_many_individual_cells} individual cells. They should be spread out that is, you can pretty much see just this one cell in the frame."
            note "We also want #{how_many_group_3or4_cells} clumps of about 3 or 4 cells together but spread far from others."
            note "The user left you a note: #{note_about_choosing_cells}"
            note "Everytime you find one, click on the checkbox in the XY tab line, below Point Name. It will store the positions. You can then move teh stage and search for new cells."
            note "Make sure that in advance settings, 'execute before loop' is checked and the file should be C/Auxin/Macro/z_drift"
            image "nd_acquisition_xy"
        }
        show {
            title "Run and Save"
            warning "Always switch off the room light when you take images and keep the curtain close."
            note "Verify your nd_acquisition will work: click on the '1 time loop'. Wait and see that the resulting images are good. Discard after."
            note "If not, fix it by going over the previous steps again."
            note "If it looks good, select 'save to file' in ND Acquisition. Path is 'XXXX' and filename is #{Date.today.to_s}_#{overnight_id}."
            note "Leave the room dark: lights must be off, curtain closed."
        }


    end
end
