needs "aqualib/lib/standard"
needs "aqualib/lib/cloning"

#doc https://github.com/klavinslab/aquarium/blob/master/doc/Krill.md

class Protocol

    include Standard
    include Cloning

    def arguments
        {
          io_hash: {},
          duration: "6h",
          intervals: "3min",
          how_many_individual_cells: 5,
          how_many_group_3or4_cells: 3,
          note_about_choosing_cells: "Good luck",
          channels: "GFP,mCherry,YFP",
          overnight_id:0,
          debug_mode: "No"
        }
    end

    def main
      io_hash = input[:io_hash]
      io_hash = input if !input[:io_hash] || input[:io_hash].empty?
      io_hash = { duration: input[:duration],
        intervals: input[:intervals],
        how_many_individual_cells: input[:how_many_individual_cells],
        how_many_group_3or4_cells: input[:how_many_group_3or4_cells],
        note_about_choosing_cells: input[:note_about_choosing_cells],
        channels: input[:channels],
        overnight_id:input[:overnight_id],
        debug_mode: input[:debug_mode] }.merge io_hash
      if io_hash[:debug_mode].downcase == "yes"
        def debug
          true
        end
      end

        duration = io_hash[:duration]
        intervals = io_hash[:intervals]
        channels = io_hash[:channels]
        how_many_individual_cells= io_hash[:how_many_individual_cells]
        how_many_group_3or4_cells=io_hash[:how_many_group_3or4_cells]
        note_about_choosing_cells=io_hash[:note_about_choosing_cells]
        overnight_id = io_hash[:overnight_ids][0]

        #use take items
        #take items, interactive: true



        show {
          title "NIS Element configuration"
          note "We will configure the software to perform the acquisition."

        }

        #
        show {
            title "NIS Element: live view"
            check "Go to the computer, start NIS Element."
            check "In the menu, choose 'Calibration > Optical configuration'. Then click 'Restore' and choose 'Dropbox/Microscope/yeast_optical_configuration.xml'"
            check "Click on the play button and then Auto Scale LUTs whithin the live view."
            note "Make sure you can also see Ti-pad and ND_Acquisition. If not, left click and select in Acquisition Controls."
            note "In the Ti-pad, you might need to click on the red/green button to turn on the light. It should be at 4M. VERIFY!!!!!!!"
            image "live_view"
        }
        show {
            title "Load experiment and configure time"
            check "In ND Acquisition, choose 'load' at the bottom and select file 'Dropbox/Microscope/FP_Yeast.xml'"
            note "Start with the 'time' tab."
            check "Configure it so that the duration is #{duration} MINUTE(S) and the intervals is #{intervals} MINUTE(S)."
            note "In advanced settings, verify that Autofocus has 'step in range' selected, it will adjust Z so that the cells remain in focus overtime."
            image "nd_acquisition_time"
        }
        show {
            title "Configure lambda"
            note "In ND Acquisition, choose the 'lambda' tab."
            note "ALWAYS leave brightfield on."
            check "The user wants the following channels: #{channels}. Select those accordingly. (If it is empty or None, leave only brightfield checked.)"
            note "In Advanced settings, verify that Brightfield will execute before capture C/Auxin/Macros/preset_lamp.mac"
            note "Again, make sure brightfield is selected, we always need at least that one!"
        }

        show {
            title "Configure XY"
            note "In ND Acquisition, choose the 'XY' tab."
            warning "If the controllers do not work or you can't select the tab: got to Devices, Manage Devices. Select NikonTi, click connect. Select RFA, click connect. If it is still not working, restart both the microscope and the computer, and reconnect devices."
            note "Now you are going to look for cells to image and you will record their positions!"
            note "Play with both the controllers Z (just barely) and XY to find yeast cells."
            warning "Z has a small sweet spot. It can be tricky to find. The oil should spread touching the bottom of the dish. But you should not go too high with Z as it will push the dish out of its mount."
            check "You will need to find #{how_many_individual_cells} individual cell(s). They should be spread out that is, you can pretty much see just this one cell in the frame."
            check "You will also need to find #{how_many_group_3or4_cells} clump(s) of about 3 or 4 cells together but spread far away from others as well."
            note "The user left you a note: \"#{note_about_choosing_cells}\""
            note "Everytime you find a good position, click on the checkbox in the XY tab line, below Point Name. It will store the current position. You can then move and search for new cells."
            note "Check that in advanced settings, 'execute before loop' is checked and the file should be C/Auxin/Macro/z_drift"
            image "nd_acquisition_xy"
        }
        show {
            title "Save and Run"
            warning "Always switch off the room light when you take images and keep the curtain close."
            check "Verify your nd_acquisition will work: click on the '1 time loop'. Wait and see wether the resulting images are good. Discard after."
            note "If not, fix it by going over the previous steps again."
            check "If it looks good, select 'save to file' in ND Acquisition. Path is 'Dropbox/Microscope/AquariumYMTask_ndfiles' and filename is #{Date.today.to_s}_#{overnight_id}."
            check "Click 'Run now'!"
            note "Leave the room dark: lights must be off, curtain closed. The acquisition will last #{duration}. You may come back and clean up (which is the next protocol after that)."
        }
        if io_hash[:task_id]
            task = find(:task, id: io_hash[:task_id])[0]
            set_task_status(task,"timelapse_started")
        end

        return { io_hash: io_hash }


    end
end
