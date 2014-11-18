Cloning the Aquarium way
===

Fragment Construction
---
#### How does it work?
The Fragment Construction workflow takes fragment sample id as input and produces corresponding fragment stock as output. In detail, the workflow can be started by scheduling build_fragment metacol, it pools all the fragment sample ids submitted to the Fragment Construction task, build each fragment using the information entered into the sample field through the process of PCR, pour gel, run gel, cut gel and purify gel.

For each fragment sample, it finds the 1ng/µL plasmid stock of the template defined in the sample field and finds the primer aliquot for the forward primer and reverse primer. It averages the T Anneal data in the forward and reverse primer field and uses that as the desired annealing temperature for the PCR. Currently we have 3 thermal cyclers, therefore the workflow groups all PCRs into 3 temperatures, 70 C, 67 C, 64 C. The workflow runs the PCR reaction for all fragments, then pours a certain number of gels based on how many fragments are going to be built, runs the gel and then cut the gel based on the length info in the fragment field, finnally purifies the gel and results in a fragment stock with concentration recorded in the datum field. If the gel band does not match the length info, the corresponding gel lane will not be cut and no fragment stock will be produced for that fragment.

The workflow manages the status of each task, the status could be "waiting for ingredients", "ready", "pcr", "gel run", "gel cut", "done" depending on how each task progresses. Initially, a task should be labeld as "waiting for ingredients", "ready". When the build_fragment metacol started, if any fragment sample submitted into the task has missing information such as missing length info, missing template or primers, it will be placed in the "waiting for ingredients"

#### Input requirements
You need to enter Length, Template, Forward Primer, Reverse Primer for your submitted fragment, which can be editted in the fragment sample page by clicking Edit Fragment Information. The template currently is a Plasmid and you need to have at least one Plasmid Stock there. You need to have Primer Aliquots for your linked Forward Primer and Reverse Primer. If anyone of this information is missing or Plasmid Stock and Primer Aliquots are not there, your submitted tasks that contains this fragment will be pushed to the waiting for ingredients stack and will not be built.
#### How to submit a task?
To submit a Fragment Construction task, go to Tasks/Fragment Constructions, click New Fragment Construction, enter Name as an indentifier for you to recognize, could be any string that does not conflict with exisiting task names under Fragment Construction task, leave the Status as waiting for ingredients, enter the fragment id by either directly enter the sample id or click the Fragment button to use the finder UI to find your fragment sample under projects.

Gibson Assembly
---

Plasmid Verficiation
---

Yeast Transformation
---

Yeast Strain QC
---
