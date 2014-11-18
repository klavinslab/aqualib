Cloning the Aquarium way
===

Fragment Construction
---
#### How does it work?
The Fragment Construction workflow takes fragment sample id as input and produces corresponding fragment stock as output. In detail, it pulls all the fragment sample ids submitted to the Fragment Construction task, for each fragment sample, it finds the 1ng/µL plasmid stock of the template defined in the sample field, it finds the primer aliquot for the forward primer and reverse primer. It averages the T Anneal data in the forward and reverse primer field and uses that as the desired annealing temperature for the PCR. Due to the current number limit of thermal cycler, the workflow groups all PCRs into 3 temperatures, 70 C, 67 C, 64 C.

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
