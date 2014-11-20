Cloning the Aquarium way
===

Fragment Construction
---
#### How it works?
The Fragment Construction workflow takes fragment sample id as input and produces corresponding fragment stock as output. In detail, the workflow can be started by scheduling build_fragment metacol, it pools all the fragment sample ids submitted to the Fragment Construction task, build each fragment using the information entered into the sample field through the process of running PCR, pour_gel, run_gel, cut_gel and purify_gel protocols. 

On how the information is processed, for each fragment sample, it finds the 1ng/µL plasmid stock of the template defined in the sample field, if 1ng/µL plasmid stock is not existed, it will try to dilute from the plasmid stock if there is any. It also finds the primer aliquot for the forward primer and reverse primer. It averages the T Anneal data in the forward and reverse primer field and uses the average as the desired annealing temperature for the PCR. The workflow groups all PCRs into 3 temperatures, 70 C, 67 C, 64 C based on the desired annealing temperature. The workflow runs the PCR reactions for all fragments based on all above information and stocks it finds, then pours number of gels based on number of PCR reactions, runs the gel and then cut the gel based on the length info in the fragment field, finally purifies the gel and results in a fragment stock with concentration recorded in the datum field and placed in the M20 boxes. If a gel band does not match the length info, the corresponding gel lane will not be cut and no fragment stock will be produced for that fragment.

The workflow manages the status of each task, the status could be "waiting for ingredients", "ready", "pcr", "gel run", "gel cut", "done" depending on how each task progresses. Initially, a task is labeled as "waiting for ingredients" or "ready". When the build_fragment metacol started, it processes all tasks in "waiting for ingredients" and "ready" stack, if all fragments in a task have all information and stocks ready, it will push the task to the "ready" stack and fires up all PCR reactions. If any fragment submitted into the task has missing information or stock, it will be labeled as "waiting for ingredients".

#### Input requirements
You need to enter length, template, forward primer, reverse primer for your submitted fragment, which can be edited in the fragment sample page by clicking Edit Fragment Information. The template currently is restricted to a plasmid and you need to have at least one Plasmid Stock for the plasmid in the inventory. You need to have primer aliquots for your linked forward primer, reverse primer. If anyone of this information is missing or plasmid stock and primer aliquots are not there, your submitted tasks that contains this fragment will be pushed to the "waiting for ingredients" stack and will not be built.

#### How to submit a task?
To submit a Fragment Construction task, go to Tasks/Fragment Constructions, click New Fragment Construction, enter Name as an identifier for you to recognize, could be any string that does not conflict with existing task names under Fragment Construction task, leave the Status as waiting for ingredients, enter the fragment id by either directly enter the sample id or click the Fragment button to use the finder UI to find your fragment sample under projects.

Gibson Assembly
---
#### How it works?
The Gibson Assembly workflow takes a Gibson recipe, a **plasmid** you want to build from a number of **fragments**, as input and produces an E coli Plate of Plasmid for the **plasmid**. In detail, the workflow can be started by scheduling gibson_assembly metacol, it pools all Gibson recipes submitted to the Gibson Assembly tasks and sequentially starts gibson, ecoli_transformation, plate_ecoli_transformation, image_plate protocols to produce plates of E coli colonies that contain the plasmids.

At the beginning of gibson protocol, the workflow processes all the Gibson Assembly tasks labled as "waiting for fragments" and "ready", if fragments in a task all have fragment stocks ready and length info entered in the sample field, it will push the task to "ready" stack and fires up the gibson reactions whereas if any stock is missing or length info is missing, it will push the task to "waiting for fragments" stack. The gibson protocol uses the concentration data and length info for the fragment stocks to calculate volumes of fragment stocks to add to achieve approximate equal molar concentrations for each fragment in the reaction. Notably, if a fragment stock that needs to be used in the gibson reaction exists but misses the concentration data, the protocol will instruct the techs to measure the concentration and record the data before starting all the reactions. The ecoli_transformation protocol takes all the gibson reaction results produced by the gibson protocol and start electroporation to transform them into DH5alpha electrocompetent aliquots. It will plate the cells directly on LB+Amp after transformation if the bacterial marker defined in the plasmid sample filed is Amp (or AMP, AmP, Amp_is_my_favorite_bacterial_marker) and incubate in 37 C incubator otherwise. The plate_ecoli_transformation protocol plates all Transformed E. coli Aliquots sitting in 37 C incubator on corresponding selective media plates based on the bacterial marker info provided and then place in 37 C incubator. The image_plate protocol takes all the incubated plates after 18 hours, take pictures, upload them in the Aquarium and also count the colonies on each plate. If the number of colonies on a plate is zero, the protocol will instruct the tech to discard the plate, otherwise, it will parafilm all the plates and put into an available box in the deli fridge and update the inventory location.

The workflow also manages all the status of the tasks like described in the fragment construction section, you can check the progress of you task by clicking each status tab. If you notice that your tasks are sitting in the "waiting_for_fragments" for too long, you should probably read the following input requirements.

#### Input requirements
You need to enter the bacterial marker info for the plasmid and length info for the fragment. You need to ensure there is at least one fragment stock for the fragment. If you do not have a fragment stock or run out of fragment stock, the build_fragments metacol will build one for you but you need to make sure all the info in the fragment sample field are valid as the same requirements described in the fragment construction workflow. You do not have to submit this fragment building as a separate task in the fragment construction workflow, the build_fragments metacol will pull inputs from both gibson assembly and fragment construction tasks. Tasks owners can run aqualib/test/check_tasks_inputs.rb to check if their inputs are valid after submitting the gibson assembly tasks.

#### How to submit a task?
To submit a Gibson Assembly task, go to Tasks/Gibson Assembly, click New Gibson Assembly, enter Name as an identifier for you to recognize, could be any string that does not conflict with existing task names under Gibson Assembly task, leave the Status as "waiting for fragments" or change it to "ready" if you want, enter the plasmid id and fragment id by either directly enter the sample id or use the finder UI by clicking the button alongside the input box.

Plasmid Verification
---
#### How it works?
The plasmid verification workflow takes an E coli Plate of Plasmid, produces plasmid stocks from specified number of colonies on that plate, and produces sequencing results by sending sequencing reactions with specified primers. In detail, the workflow can be started by scheduling plasmid_verification metacol, it pools all plasmid verification tasks and start specified number of overnights from each plate, produces plasmid stocks using miniprep from overnights that have growth, sets up sequencing reactions for each plasmid stock with specified primers, sends to sequencing facility (currently Genewiz), and finally uploads the sequencing results into Aquarium.

The workflow also manages all the status of the tasks as "waiting", "overnight", "plasmid extracted", "send to sequencing", "results back", you can easily track the progress of your tasks.

#### Input requirements
For each plate, you need to enter the bacterial marker info (Amp, Kan or Chlor) in the plasmid sample field. You need to specify num_colonies (a number) and primer_ids (an array of primer sample ids) for each plate_id for each plate in the task input. Notably, since each plate_id corresponds to an array of primers, the primer_ids for all plate_ids will be an array of arrays. Apparently, the array length of plate_ids, num_colonies, primer_ids should be the same.

#### How to submit a task?
To submit a Plasmid Verification task, go to Tasks/Plasmid Verification, click New Plasmid Verification, enter Name as an identifier for you to recognize, could be any string that does not conflict with existing task names under Gibson Assembly task, leave the Status as "waiting", enter the item id of the E coli plate in plate_ids that you want to extract and verify plasmid from, enter a number in num_colonies to indicate how many colonies you want to pick from each plate and also enter **sample id** of primers for setting up sequencing reaction for extracted plasmid from each plate. You can also enter your initials so that in the sequencing results it will have you initials in the file name so you can easily identify your results among others.

Yeast Transformation
---

Yeast Strain QC
---
