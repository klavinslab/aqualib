Cloning the Aquarium way
===

Fragment Construction
---
#### How it works?
The Fragment Construction workflow takes fragment sample id as input and produces corresponding fragment stock as output. In detail, the workflow can be started by scheduling build_fragment metacol, it pools all the fragment sample ids submitted to the Fragment Construction task, build each fragment using the information entered into the sample field through the process of PCR, pour_gel, run_gel, cut_gel and purify_gel. 

On how the information is processed, for each fragment sample, it finds the 1ng/µL plasmid stock of the template defined in the sample field, if 1ng/µL plasmid stock is not existed, it will try to dilute from the plasmid stock if there is any. It also finds the primer aliquot for the forward primer and reverse primer. It averages the T Anneal data in the forward and reverse primer field and uses the average as the desired annealing temperature for the PCR. The workflow groups all PCRs into 3 temperatures, 70 C, 67 C, 64 C based on the desired annealing temperature. The workflow runs the PCR reactions for all fragments based on all above information and stocks it finds, then pours number of gels based on number of PCR reactions, runs the gel and then cut the gel based on the length info in the fragment field, finnally purifies the gel and results in a fragment stock with concentration recorded in the datum field and placed in the M20 boxes. If a gel band does not match the length info, the corresponding gel lane will not be cut and no fragment stock will be produced for that fragment.

The workflow manages the status of each task, the status could be "waiting for ingredients", "ready", "pcr", "gel run", "gel cut", "done" depending on how each task progresses. Initially, a task is labeld as "waiting for ingredients" or "ready". When the build_fragment metacol started, it processes all tasks in "waiting for ingredients" and "ready" stack, if all fragments in a task have all information and stocks ready, it will push the task to the "ready" stack and fires up all PCR reactions. If any fragment submitted into the task has missing information or stock, it will be labeled as "waiting for ingredients".

#### Input requirements
You need to enter Length, Template, Forward Primer, Reverse Primer for your submitted fragment, which can be editted in the fragment sample page by clicking Edit Fragment Information. The template currently is a Plasmid and you need to have at least one Plasmid Stock there. You need to have Primer Aliquots for your linked Forward Primer and Reverse Primer. If anyone of this information is missing or Plasmid Stock and Primer Aliquots are not there, your submitted tasks that contains this fragment will be pushed to the "waiting for ingredients" stack and will not be built.

#### How to submit a task?
To submit a Fragment Construction task, go to Tasks/Fragment Constructions, click New Fragment Construction, enter Name as an indentifier for you to recognize, could be any string that does not conflict with exisiting task names under Fragment Construction task, leave the Status as waiting for ingredients, enter the fragment id by either directly enter the sample id or click the Fragment button to use the finder UI to find your fragment sample under projects.

Gibson Assembly
---
#### How it works?
The Gibson Assembly workflow takes a Gibson recipe, a **plasmid** you want to build from a number of **fragments**, as input and produces an E coli Plate of Plasmid for the **plasmid**. In detail, the workflow can be started by scheduling gibson_assembly metacol, it pools all Gibson recipes submitted to the Gibson Assembly tasks and sequentially starts gibson, ecoli_transformation, plate_ecoli_transformation, image_plate protocols to produce plates of E coli colonies that contain the plasmids.


Plasmid Verficiation
---

Yeast Transformation
---

Yeast Strain QC
---
