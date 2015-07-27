Cloning the Aquarium way
===

This documentation is used as a reference for using Aquarium to do cloning work via Tasks. A read through is recommended for new Aquarium users. In case you have any questions, contact this document authors below.

**Authors List**

Yaoyu Yang <yaoyu@uw.edu>, wrote the Task Common Routines and all the Task specific sections.

Miles Gander <gander.miles@gmail.com>, wrote the Samples and Items section.

Michelle Parks <mnparks@uw.edu>, wrote the Aquarium Routines section.

Aquarium Routines
---
#### Creating an Aquarium Username

#### Logging In and Out

#### Searching for a Sample

#### Discussion Board

#### Aborting Jobs and Metacols

#### Job Logs

Samples and Items
---
#### Samples and Items

In Aquarium there is a hierarchy of different object types. In general, a sample is the definition of something like a plasmid called "pLAB1". Each sample has a specific sample ID. The sample pLAB1 has a specific sample type, in this case plasmid. Each sample has specific container types. For example, for a plasmid sample type, the containers are plasmid stocks, plasmid glycerol stocks, 1 ng/µl stocks, ect. There can be multiple copies of each container type of a sample that exist physically in the lab at the same time. Each container type item has a specific item ID in Aquarium.

#### Creating a new sample

To define a new sample go to the inventory dropdown menu and select the desired sample type for the new sample. (Plasmid, Primer, Yeast Strain, etc.) Then, for example, to define a new plasmid click on the "New Plasmid" button at the bottom of the page. This pulls up a page with information fields to fill out. The "New Plasmid" page has fields for the name of the plasmids, the project of the sample, a description of the plasmid, sequencing verification and other relevant information. Other sample types have similar informaiton field pages that must be completed to define a new sample. When the fields are completed click on "Save Sample Information" and Aquarium will assign a unique sample number to the new sample.

#### Creating new items

Creating new items of samples is relatively easy. For the most part items of samples will be created automatically through protocols, but there are times where an item may need to be entered outside of a protocol. To do this, go to the inventory page of the sample of which a new item is desired. Click on the desired container type and click the "New" button and Aquarium will create a new item with a unique item ID number.

#### Creating New Sample Types

If new protocol or new task requires a new sample type, it can be defined in the following manner. First, click on the inventory dropdown menu and click on the "Sample Type Definitions" option. This leads to a page with all the defined sample types currently available in the system. At the bottom of this page there is a button labeled "New Sample type", this will open a page with a space for a name, a descripiton, and up to 8 fields. These fields can be defined to take strings, numbers, urls, or links to any other sample type. Not all fields necessarily need to be used. Once all of the information fields on this page are filled out, clicking the "Save Sample Type" will define the new sample. 

#### Creating New Container Types

Each sample type has different forms it can exist in. In the Aquarium system these forms are referred to as container types. To define a new container type for a given sample, navigate back to the "Sample Type Definitions" page. Once there, click the link to the name of the sample type you wish to add a container type too. The link will bring up a page that lists the fields of the sample type and all of its containers. At the bottom of the listed containers, there is an "add" button that pulls up a page with a number of different data fields to fill out. The fields include, name of the container type, description, and the location prefix for the location wizard. Additionally, there are a few other optional fields present such as cost per container, vendor and safety information. The functionality for using the information in the additional fields is currently being developed. 

#### Deleting Items

Deleting items in Aquarium is easy. Just navigate to the sample page of the item to be deleted and click on the black "x" to the right of the item. The only consideration when manually deleting an item is to make sure the item is physically removed from the location it had been occupying. That way new items assigned a location by the location wizards will be able to be placed in their correct, unoccupied, slots.

#### Deleting Samples

Deleting sample is also relatively easy. Go to the inventory drop down tab, select the sample type of the sample to be deleted and then click on the black "x" to the right of the sample name. The same consideration of physical removal for deleting items exists for deleting samples. Since a sample can have many items associated with it, all of the associated items with the sample being deleted will need to be physically removed from their inventory slots.

Task Routines
---
#### How to enter new tasks?
Assume a task prototype has the name of Awesome Task (such as Fragment Construction). To enter new tasks and track all existing tasks progress and information, go to Tasks > Awesome Tasks. You can click the button New Awesome Task to enter inputs for new tasks: you can enter anything that helps you recognize in the Name field, leave the Status as waiting by default, enter the rest of arguments referring to the **input requirements** of each specific task documentation in the following sections. If an argument input has "+", "-" buttons, it means the argument takes an array of inputs, if the input has two "+", "-" button, it means the argument takes an array of array inputs. You can also click the status bar such as waiting, ready, canceled, etc to track all your tasks. You can use search bar to filter out your tasks of interest by typing user name or tasks name. It starts with your user name as default. You can check your input by running aqualib/workflows/general/tasks_inputs.rb, enter Awesome Task as the argument in task_name and enter your user name in the group argument. After you run, you can check the notifications of the tasks to see what's wrong with your input.

#### How to execute tasks?

**Lab manager perspective**

To actually carry out the Awesome Task for real in the wetlab, in most cases (except for Sequencing Verification), the lab manager need to schedule the metacol/protocols corresponding to this Awesome Task. Noting that it only needs to be started once to execute all the Awesome Tasks that are waiting or ready, so the best practice is to start this regularly every day at a determined time so users can enter their tasks before that time. To start the metacol/protocols, go to Protocols > Under Version Control, find the Github repo tree, click workflows/metacol, then click the file named awesome_task.oy, leave the debug_mode empty, assign to a group that is going to experimentally perform all the protocols, normally choose technicians, then click Launch! All the protocols will then be subsequently scheduled and can be accessed from Protocols > Pending Jobs.

**User perspective**

For each new task entered, it will start as waiting by default. A protocol named tasks_inputs.rb, normally the first protocol in the metacol associated with this task, will process all the tasks in the waiting or ready status and change its status to ready if all the input requirements are fulfilled and change to waiting if not. All the tasks in the ready will be batched and being processed by subsequent protocols in the metacol to actually instruct technicians to perform guided steps in the lab to carry out actual experiments.

If you don't want a task to be executed anymore, change its status to canceled. You are advised only to do this while your task is in waiting or ready and the metacol has not been started, if your task already been processed and progressed to other status, contact the Lab manager to discuss alternatives if you don't want a task to be executed anymore.

Fragment Construction
---
#### How it works?
The Fragment Construction workflow takes fragment sample id as input and produces corresponding fragment stock as output. It pools all the fragment sample ids submitted to the Fragment Construction tasks, build each fragment using the information entered into the sample field through the process of running PCR, pour_gel, run_gel, cut_gel and purify_gel protocols.

For each fragment, it finds the 1ng/µL plasmid stock of the fragment. If a 1ng/µL plasmid stock does not exist, it will try to dilute from the plasmid stock if there is any. It also finds the primer aliquot for the forward primer and reverse primer. It uses the T Anneal data in the forward and reverse primer field and uses the lower of the two as the desired annealing temperature for the PCR. The workflow first clusters all PCRs into 3 temperature groups, >= 70 C, 67 -70 C, < 67 C based on the desired annealing temperature. Then it finds the lowest annealing temperature in each group and uses that as the final annealing temperature. The workflow runs the PCR reactions for all fragments based on above information and stocks it finds, then pours a number of gels based on the number of PCR reactions, runs the gel and then cut the gel based on the length info in the fragment field, finally purifies the gel and results in a fragment stock with concentration recorded in the datum field and placed in the M20 boxes. If a gel band does not match the length info, the corresponding gel lane will not be cut and no fragment stock will be produced for that fragment.

#### Input requirements
| Argument name   |  Data type | Data structure | Inventory type | Sample property | Item required |
|:---------- |:------------- |:------------- |:------------- |:------------- |:------------- |
| fragments  |  sample id |  array | Fragment | Length, Template, Forward Primer, Reverse Primer  | None |

The template can be a plasmid, fragment, yeast strain, or E coli strain. Corresponding item shown in the table below need to be existed in the inventory for the fragment construction task able to be pushed to ready.

| Template   |      Item required |
|:---------- |:------------- |
| Plasmid  |  Plasmid stock or 1ng/µL Plasmid Stock  |
| Fragment | Fragment Stock or 1ng/µL Fragment Stock |
| Yeast Strain | Lysate or Yeast cDNA if no Lysate  |
| E coli strain | E coli Lysate or Genome Prep if no E coli Lysate |

Gibson Assembly
---
#### How it works?
The Gibson Assembly workflow takes a Gibson recipe, a **plasmid** you want to build from a number of **fragments**, as input and produces an E coli Plate of Plasmid for the **plasmid**. In detail, the workflow can be started by scheduling gibson_assembly metacol, it pools all Gibson recipes submitted to the Gibson Assembly tasks and sequentially starts gibson, ecoli_transformation, plate_ecoli_transformation, image_plate protocols to produce plates of E coli colonies that contain the plasmids.

At the beginning of gibson protocol, the workflow processes all the Gibson Assembly tasks labled as "waiting" and "ready", if fragments in a task all have fragment stocks ready and length info entered in the sample field, it will push the task to "ready" stack and fires up the gibson reactions whereas if any stock is missing or length info is missing, it will push the task to "waiting" stack. The gibson protocol uses the concentration data and length info for the fragment stocks to calculate volumes of fragment stocks to add to achieve approximate equal molar concentrations for each fragment in the reaction. Notably, if a fragment stock that needs to be used in the gibson reaction exists but lacks the concentration data, the protocol will instruct the techs to measure the concentration and record the data before starting all the reactions. The ecoli_transformation protocol takes all the gibson reaction results produced by the gibson protocol and start electroporation to transform them into DH5alpha electrocompetent aliquots. It will then incubate all transformed aliquots in 37 C incubator for 30 minutes. The plate_ecoli_transformation protocol plates all Transformed E. coli Aliquots sitting in 37 C incubator on corresponding selective media plates based on the bacterial marker info provided and then place back in 37 C incubator. The image_plate protocol takes all the incubated plates after 18 hours, take pictures, upload them in the Aquarium and also count the colonies on each plate. If the number of colonies on a plate is zero, the protocol will instruct the tech to discard the plate, otherwise, it will parafilm all the plates and put into an available box in the deli fridge and update the inventory location.

The workflow also manages all the status of the tasks like described in the fragment construction section, you can check the progress of you task by clicking each status tab. If you Gibson reaction successfully has colonies, it will be pushed to the "imaged and stored in fridge" tab, if no colonies show up, it will be pushed to the "no colonies" tab. If you notice that your tasks are sitting in the "waiting" for too long, you should probably read the following input requirements.

#### Input requirements

| Argument name   |  Data type | Data structure | Inventory type | Sample property | Item required |
|:---------- |:------------- |:------------- |:------------- |:------------- |:------------- |
| plasmid  |  sample id |  integer | Plasmid | Bacterial Marker, Length | None |
| fragments  |  sample id |  array | Fragment | Length | Fragment Stock |

You need to ensure there is at least one fragment stock for the fragment. If you do not have a fragment stock or run out of fragment stock, new fragment construction task will automatically submitted for you.

Plasmid Verification
---
#### How it works?
The plasmid verification workflow takes an E coli Plate of Plasmid, produces plasmid stocks from specified number of colonies on that plate, and produces sequencing results by sending sequencing reactions with specified primers. In detail, the workflow pools all plasmid verification tasks and starts specified number of overnights from each plate, produces plasmid stocks using miniprep from overnights that have growth, sets up sequencing reactions for each plasmid stock with specified primers, sends to a sequencing facility (currently Genewiz), and finally uploads the sequencing results into Aquarium.

#### Input requirements
| Argument name   |  Data type | Data structure | Inventory type | Sample property | Item required |
|:---------- |:------------- |:------------- |:------------- |:------------- |:------------- |
| plate_ids  |  item id  | array | E coli Plate of Plasmid | Bacterial Marker (e.g. Amp, Kan, etc) | E coli Plate of Plasmid |
| num_colonies | integer (1-10) | array | N/A | N/A | N/A |
| primer_ids | sample id | array of arrays | Primer | Not required | Primer Aliquot |

Sequencing
---
#### How it works?
The sequencing workflow takes plasmid stocks and prepares sequencing reaction mix in stripwells with corresponding primer stocks. It submits orders to Genewiz and send to do Sanger sequencing. When sequencing results are back, it guides the technicians to upload the results into Aquarium.

#### Input requirements
| Argument name   |  Data type | Data structure | Inventory type | Sample property | Item required |
|:---------- |:------------- |:------------- |:------------- |:------------- |:------------- |
| plasmid_stock_ids  |  item id | array | Plasmid Stock or Fragment Stock | Length | Plasmid Stock or Fragment Stock |
| primer_ids | sample id | array of arrays | Primer | Not required | Primer aliquot |

Each item id in the plasmid_stock_ids uses the corresponding subarray of primer_ids to set up sequencing reaction.

Yeast Transformation
---
#### How it works?
The yeast transformation workflow takes a yeast strain id as input and produces a yeast plate through transforming a digested plasmid into a parent yeast strain. The yeast strain sample field defines the integrant and the parent yeast strain. The workflow can be scheduled by starting yeast_transformtion metacol. In detail, it pools all the yeast transformation tasks, starts overnights for the parent strains that do not have enough yeast competent cells for this batch of transformation. If there is any overnights, it then progresses to inoculate overnights into large volume growth and make as many as possible yeast competent cells and places in the M80C boxes. In the meantime, it digests the plasmid stock of the plasmid that specified in the integrant field of the yeast strain. It then transforms the digested plasmids into the parent strain yeast competent cells and plates them on selective media plates using info specified in the yeast marker field of the plasmid. The workflow currently can also handle plasmids with KanMX yeast marker, it will incubate the transformed mixtures for 3 hours and then plate on +G418 plates.

#### Input requirements
 The parent is to link a yeast strain as your parent strain for this transformation and integrant links to the plasmid you are planning to digest and transform into the parent strain to make the yeast transformed strain. You need to make sure there is at least one plasmid stock for the plasmid. You also need to make sure the yeast marker field in properly entered in the plasmid sample page.

| Argument name   |  Data type | Data structure | Inventory type | Sample property | Item required |
|:---------- |:------------- |:------------- |:------------- |:------------- |:------------- |
| yeast_transformed_strain_ids  |  sample id | array | Yeast Strain | Parent, Integrant (or Plasmid) | None |


Yeast Strain QC
---
#### How it works?
The yeast strain QC workflow takes a yeast plate and produces QCPCR results presented in a gel image. In detail, the workflow can be scheduled by starting yeast_strain_QC metacol. The workflow pools all yeast strain QC tasks and start lysates for each yeast plate from specified number of colonies as entered in the task input, then it sets up PCR reactions with primers specified in QC Primer 1 and QC Primer 2 in the corresponding yeast strain sample field. It then pours a number of gels based on number of PCR reactions, runs the gel with the PCR results, takes a picture of the gel and uploads it in the Aquarium where you can find in the job log of image_gel.

When picking up colonies from a yeast plate, the workflow follows the following rules. If the plate has only one region and some colonies are marked with circle as c1, c2, c3, ..., it will pick these colonies starting from c1 until reach the specified number of colonies. If the plate has several regions, e.g. a streaked plates with different regions, and if each region is marked as c1, c2, c3, ..., it will pick one colony from each region until reach the specified number of colonies. If nothing is marked up, it will randomly pick up medium to large size colonies and mark them with c1, c2, c3.

The workflow manages all the status of the tasks as "waiting", "lysate", "pcr", "gel run", "gel imaged", you can easily track the progress of your tasks.

#### Input requirements
| Argument name   |  Data type | Data structure | Inventory type | Sample property | Item required |
|:---------- |:------------- |:------------- |:------------- |:------------- |:------------- |
| yeast_plate_ids  |  item id | array | Yeast Plate | QC Primer 1, QC Primer 2 | Primer Stock for QC Primer 1 and QC Primer 2 |
| num_colonies  |  integer | array | N/A | N/A | N/A |

num_colonies is to indicate how many colonies you want to pick from each plate for QC. The array length of yeast_plate_ids and num_colonies need to be the same so they are one to one correspondence.

Yeast Mating
---
#### How it works?
For each yeast mating task, the yeast mating workflow takes two yeast strains as input and produces a mated yeast strain on a selective media plate. It automatically creates a new yeast strain in the database where the name of the new yeast strain is generated by concatenating two parent yeast strains' names. In detail, it uses glycerol stock from each yeast strain and inoculates each into 1 mL YPAD. Then mix them into 14 mL tube to incubate for at least 5 hrs. After incubation, it schedules a streak_yeast_plate protocol to streak the yeast on a selective media plate defined by the user from the task input. After 48 hrs, it schedules an image_plate protocol to image and store the plate.

#### Input requirements
| Argument name   |  Data type | Data structure | Inventory type | Sample property | Item required |
|:---------- |:------------- |:------------- |:------------- |:------------- |:------------- |
| yeast_mating_strain_ids  |  sample id | array with size 2 | Yeast Strain | Not required | Yeast Glycerol Stock |
| yeast_selective_plate_type  |  string | string | N/A | N/A | N/A |

yeast_selective_plate_type indicates which type of plate you intend to plate on for the mated strain, it's usually a combination of two markers, such as -TRP, -HIS or -URA, -LEU, etc.
