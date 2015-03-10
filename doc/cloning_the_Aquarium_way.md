Cloning the Aquarium way
===

Fragment Construction
---
#### How it works?
The Fragment Construction workflow takes fragment sample id as input and produces corresponding fragment stock as output. In detail, the workflow can be started by scheduling build_fragments metacol, it pools all the fragment sample ids submitted to the Fragment Construction task, build each fragment using the information entered into the sample field through the process of running PCR, pour_gel, run_gel, cut_gel and purify_gel protocols. 

On how the information is processed, for each fragment sample, it finds the 1ng/µL plasmid stock of the template defined in the sample field, if a 1ng/µL plasmid stock does not exist, it will try to dilute from the plasmid stock if there is any. It also finds the primer aliquot for the forward primer and reverse primer. It averages the T Anneal data in the forward and reverse primer field and uses the average as the desired annealing temperature for the PCR. The workflow first clusters all PCRs into 3 temperature groups, >= 70 C, 67 -70 C, < 67 C based on the desired annealing temperature. Then it finds the loweset annealing temperature in each group and uses that as the final annealing temperature. The workflow runs the PCR reactions for all fragments based on all above information and stocks it finds, then pours number of gels based on number of PCR reactions, runs the gel and then cut the gel based on the length info in the fragment field, finally purifies the gel and results in a fragment stock with concentration recorded in the datum field and placed in the M20 boxes. If a gel band does not match the length info, the corresponding gel lane will not be cut and no fragment stock will be produced for that fragment.

The workflow manages the status of each task, the status could be "waiting", "ready", "pcr", "gel run", "gel cut", "done", "canceled" depending on how each task progresses. Initially, a task is labeled as "waiting" or "ready". When the build_fragment metacol started, it processes all tasks in "waiting" and "ready" stack, if all fragments in a task have all information and stocks ready, it will push the task to the "ready" stack and fires up all PCR reactions. If any fragment submitted into the task has missing information or stock, it will be labeled as "waiting".

#### Input requirements
You need to enter **Length**, **Template**, **Forward Primer**, **Reverse Primer** for your submitted fragment, which can be edited in the fragment sample page by clicking Edit Fragment Information. The template currently is restricted to a plasmid and you need to have at least one Plasmid Stock for the plasmid in the inventory. You need to have primer aliquots for your linked forward primer, reverse primer. If anyone of this information is missing or plasmid stock and primer aliquots are not there, your submitted tasks that contains this fragment will be pushed to the "waiting" stack and will not be built.

#### How to submit a task?
To submit a fragment construction task, go to Tasks/Fragment Constructions, click New Fragment Construction, enter Name as an identifier for you to recognize, could be any string that does not conflict with existing task names under Fragment Construction task, leave the Status as waiting, enter the fragment id by either directly enter the sample id or click the Fragment button to use the finder UI to find your fragment sample under projects.

Gibson Assembly
---
#### How it works?
The Gibson Assembly workflow takes a Gibson recipe, a **plasmid** you want to build from a number of **fragments**, as input and produces an E coli Plate of Plasmid for the **plasmid**. In detail, the workflow can be started by scheduling gibson_assembly metacol, it pools all Gibson recipes submitted to the Gibson Assembly tasks and sequentially starts gibson, ecoli_transformation, plate_ecoli_transformation, image_plate protocols to produce plates of E coli colonies that contain the plasmids.

At the beginning of gibson protocol, the workflow processes all the Gibson Assembly tasks labled as "waiting" and "ready", if fragments in a task all have fragment stocks ready and length info entered in the sample field, it will push the task to "ready" stack and fires up the gibson reactions whereas if any stock is missing or length info is missing, it will push the task to "waiting" stack. The gibson protocol uses the concentration data and length info for the fragment stocks to calculate volumes of fragment stocks to add to achieve approximate equal molar concentrations for each fragment in the reaction. Notably, if a fragment stock that needs to be used in the gibson reaction exists but lacks the concentration data, the protocol will instruct the techs to measure the concentration and record the data before starting all the reactions. The ecoli_transformation protocol takes all the gibson reaction results produced by the gibson protocol and start electroporation to transform them into DH5alpha electrocompetent aliquots. It will then incubate all transformed aliquots in 37 C incubator for 30 minutes. The plate_ecoli_transformation protocol plates all Transformed E. coli Aliquots sitting in 37 C incubator on corresponding selective media plates based on the bacterial marker info provided and then place back in 37 C incubator. The image_plate protocol takes all the incubated plates after 18 hours, take pictures, upload them in the Aquarium and also count the colonies on each plate. If the number of colonies on a plate is zero, the protocol will instruct the tech to discard the plate, otherwise, it will parafilm all the plates and put into an available box in the deli fridge and update the inventory location.

The workflow also manages all the status of the tasks like described in the fragment construction section, you can check the progress of you task by clicking each status tab. If you Gibson reaction successfully has colonies, it will be pushed to the "imaged and stored in fridge" tab, if no colonies show up, it will be pushed to the "no colonies" tab. If you notice that your tasks are sitting in the "waiting" for too long, you should probably read the following input requirements.

#### Input requirements
You need to enter the **Bacterial Marker** info for the plasmid and **Length** info for the fragment. You need to ensure there is at least one fragment stock for the fragment. If you do not have a fragment stock or run out of fragment stock, the build_fragments metacol will build one for you but you need to make sure all the info in the fragment sample field are valid as the same requirements described in the fragment construction workflow. You do not have to submit this fragment building as a separate task in the fragment construction workflow, the build_fragments metacol will pull inputs from both gibson assembly and fragment construction tasks.

#### How to submit a task?
To submit a Gibson assembly task, go to Tasks/Gibson Assembly, click New Gibson Assembly, enter Name as an identifier for you to recognize, could be any string that does not conflict with existing task names under Gibson Assembly task, leave the Status as "waiting" or change it to "ready" if you want, enter the plasmid id and fragment id by either directly enter the sample id or use the finder UI by clicking the button alongside the input box.

Plasmid Verification
---
#### How it works?
The plasmid verification workflow takes an E coli Plate of Plasmid, produces plasmid stocks from specified number of colonies on that plate, and produces sequencing results by sending sequencing reactions with specified primers. In detail, the workflow can be started by scheduling plasmid_verification metacol, it pools all plasmid verification tasks and start specified number of overnights from each plate, produces plasmid stocks using miniprep from overnights that have growth, sets up sequencing reactions for each plasmid stock with specified primers, sends to a sequencing facility (currently Genewiz), and finally uploads the sequencing results into Aquarium.

The workflow also manages all the status of the tasks as "waiting", "overnight", "plasmid extracted", "send to sequencing", "results back", you can easily track the progress of your tasks.

#### Input requirements
For each E coli plate of plasmid, you need to enter the **Bacterial Marker** info (Amp, Kan or Chlor) in the plasmid sample field. You need to specify num_colonies (a number that ranges from 1-10) and primer_ids (an array of primer sample ids) for each plate in the task input. Notably, since each plate_id corresponds to an array of primers, the primer_ids for all plate_ids will be an array of arrays. Apparently, the array length of plate_ids, num_colonies, primer_ids should be the same.

#### How to submit a task?
To submit a plasmid verification task, go to Tasks/Plasmid Verification, click New Plasmid Verification, enter Name as an identifier for you to recognize, could be any string that does not conflict with existing task names under Plasmid Verification task, leave the Status as "waiting", enter the item id of the E coli plate in plate_ids that you want to extract and verify plasmid from, enter a number in num_colonies to indicate how many colonies you want to pick from each plate and also enter **sample id** of primers for setting up sequencing reaction for extracted plasmid from each plate. You can also enter your initials so that in the sequencing results it will have you initials in the file name so you can easily identify your results among others.

Yeast Transformation
---
#### How it works?
The yeast transformation workflow takes a yeast strain id as input and produces a yeast plate through transforming a digested plasmid into a parent yeast strain. The yeast strain sample field defines the integrant and the parent yeast strain. The workflow can be scheduled by starting yeast_transformtion metacol. In detail, it pools all the yeast transformation tasks, starts overnights for the parent strains that do not have enough yeast competent cells for this batch of transformation. If there is any overnights, it then progresses to inoculate overnights into large volume growth and make as many as possible yeast competent cells and places in the M80C boxes. In the meantime, it digests the plasmid stock of the plasmid that specified in the integrant field of the yeast strain. It then transforms the digested plasmids into the parent strain yeast competent cells and plates them on selective media plates using info specified in the yeast marker field of the plasmid. The workflow currently can also handle plasmids with KanMX yeast marker, it will incubate the transformed mixtures for 3 hours and then plate on +G418 plates.

#### Input requirements
For each yeast strain entered in the tasks, you need to enter the **Parent** and **Integrant** info in the sample field. The parent is to link a yeast strain as your parent strain for this transformation and integrant links to the plasmid you are planning to digest and transform into the parent strain to make the yeast transformed strain. You need to make sure there is at least one plasmid stock for the plasmid. You also need to make sure the yeast marker field in properly entered in the plasmid sample page. Noting that currently the workflow only processes plasmid entered into the integrant field since the workflow is intended for digest plasmid and integrate them into yeast genome by transformation.

#### How to submit a task?
To submit a yeast transformation task, go to Tasks/Yeast Transformation, click New Yeast Transformation, enter Name as an identifier for you to recognize, could be any string that does not conflict with existing task names under Yeast Transformation task, leave the Status as "waiting", enter the sample ids of the yeast strains you want to make.

Yeast Strain QC
---
#### How it works?
The yeast strain QC workflow takes a yeast plate and produces QCPCR results presented in a gel image. In detail, the workflow can be scheduled by starting yeast_strain_QC metacol. The workflow pools all yeast strain QC tasks and start lysates for each yeast plate from specified number of colonies as entered in the task input, then it sets up PCR reactions with primers specified in QC Primer 1 and QC Primer 2 in the corresponding yeast strain sample field. It then pours a number of gels based on number of PCR reactions, runs the gel with the PCR results, takes a picture of the gel and uploads it in the Aquarium where you can find in the job log of image_gel.

When picking up colonies from a yeast plate, the workflow follows the following rules. If the plate has only one region and some colonies are marked with circle as c1, c2, c3, ..., it will pick these colonies starting from c1 until reach the specified number of colonies. If the plate has several regions, e.g. a streaked plates with different regions, and if each region is marked as c1, c2, c3, ..., it will pick one colony from each region until reach the specified number of colonies. If nothing is marked up, it will randomly pick up medium to large size colonies and mark them with c1, c2, c3.

The workflow manages all the status of the tasks as "waiting", "lysate", "pcr", "gel run", "gel imaged", you can easily track the progress of your tasks.

#### Input requirements
For each yeast plate, you need to enter the **QC Primer 1** and **QC Primer 2** in the yeast strain sample field. YOu need to specify a number in num_colonies for each yeast_plate_id you enter to indicate how many colonies you want to QC from that plate. The array length of yeast_plate_ids and num_colonies need to be the same.

#### How to submit a task?
To submit a yeast strain QC task, go to Tasks/Yeast Strain QC, click New Yeast Strain QC, enter Name as an identifier for you to recognize, could be any string that does not conflict with existing task names under Yeast Strain QC task, leave the Status as "waiting", enter the item id of the Yeast plate in yeast_plate_ids that you want to do lysate and QCPCR from, enter a number in num_colonies to indicate how many colonies you want to pick from each plate for QC.

Yeast Mating
---
#### How it works?
For each yeast mating task, the yeast mating workflow takes two yeast strains as input and produces a mated yeast strain on a selective media plate. It automatically creates a new yeast strain in the database where the name of the new yeast strain is generated by concatenating two parent yeast strains' names. In detail, it uses glycerol stock from each yeast strain and inoculates each into 1 mL YPAD. Then mix them into 14 mL tube to incubate for at least 5 hrs. After incubation, it schedules a streak_yeast_plate protocol to streak the yeast on a selective media plate defined by the user from the task input. After 48 hrs, it schedules an image_plate protocol to image and store the plate.

#### Input requirements
For each task, you need to enter the sample id of the two yeast strains in the **yeast_mating_strain_ids** and you are allowed to only enter **two** yeast strain ids. You need to make sure each strain has at least one Yeast Glycerol Stock available. You also need to specify in the **yeast_selective_plate_type** which plate you intend to plate on, for example, it could be -TRP, -HIS or -URA, -LEU, etc. You can check your input by running aqualib/workflows/general/tasks_inputs.rb and enter Yeast Mating as the argument in task_name.




