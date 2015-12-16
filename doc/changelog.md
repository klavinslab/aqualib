Aquarium Klavins Lab Cloning Workflow
===
Changelog
---
#### 2015-12-15
  * Digest Yeast Plasmid
    * Protocol now only prompts the user to make a master mix if there is more than one plasmid stock in the job. 
    * Volumes of extra water, buffer, and enzyme for master mix now scale linearly with plasmid stock count.
  * Streak Yeast Plate
    * Total requisite YPAD plates for streaking are now consolodated into the beginning of the protocol (including streaking from glycerol stock and overnight).
    * Some instructions have been clarified.
    * Pictures have been added.
  * Fragment Analyzing Protocol
    * Some instructions have been clarified.

Updated by Garrett Newman

#### 2015-12-09
* Automatically submitted Plasmid Verification task default to pick only one colony.

#### 2015-12-06
* Add a link to the Genewiz website in sequencing protocol

#### 2015-12-04
* Update to the new OligoCard way of ordering primers. No more biochem store runs for picking up primers!

#### 2015-12-01
* Ecoli transformation and Gibson assembly task can now accept multiple antibiotic markers. For example, if you enter Amp, Kan in the Bacterial marker property in the plasmid sample page, the protocol will instruct the techs the plate on LB+Amp+Kan plate.

#### 2015-11-20
* Fragment analyzing protocol now reports the gel images in task notifications. This will make Yeast Strain QC users have easier access to gel images. (updated by Yaoyu Yang)

#### 2015-11-19
* Batched tasks to run in each workflow will be sorted by user id. This way, all the relevant tasks, samples, items in each workflow for each user will be in closer proximity so that they will have an easier time to look at the log or do any analysis. (updated by Yaoyu Yang)

#### 2015-11-18
* When digesting plasmid/fragment stock for yeast transformation, now it will take variable amount of plasmid/fragment stock based on the concentration. The rule is that between 300-500 ng/µL, take 2 µL. Outside that range, take 1000/concentration uL but restricted in the range of 0.5-15 µL. (updated by Yaoyu Yang)

#### 2015-11-17
* Streak Plate task will be automatically submitted when a new yeast glycerol stock is made. This will make tasks such as Yeast Competent Cell and Yeast Cytometry that requires divided yeast plate happens a bit faster.
* Yeast plates and divided yeast plates that are longer than 110 days (will be changed to 90 days a few weeks later) will be automatically submitted to Discard Item task and will be deleted when techs run the Discard Item workflow every day. If you don't want particular old plate to be deleted, in the item data field, write "keep_item": "Yes". (updated by Yaoyu Yang)
* Gibson Assembly will now take the oldest fragment stock (i.e. fragment stock with lowest item id) if there are multiple fragment stocks in the inventory. It used to take the newest stock based on some people's feedbacks but David Younger insists we should take the oldest fragment stock. (updated by Yaoyu Yang)

#### 2015-11-16
* Fragment Construction workflow will now produce multiple fragment stocks for the same fragments. It used to only produce one fragment stock even you submit multiple of the same fragments but now changed. Just submit multiple tasks for making the same fragment stocks or in one task enter the same fragment id multiple times. This improvement should help us producing more of the backbone fragment stocks that constantly used and running out in the Gibson Assembly. (updated by Yaoyu Yang)

#### 2015-11-13
* A smart and fair algorithm is implemented to determine which tasks to run when the tech capacity, total number of tasks the tech can run everyday, is lower than the number of tasks in the queue. Under this new algorithm, each user in the queue is guaranteed to have a quota of tasks to be run by the workflow. The quota is simply determined by the tech capacity and number of users in the queue. The remaining capacity after fulfilling each user's quota will be prorated among the remaining users until not able to be prorated and then the leftover capacity will be used to fulfill tasks sequentially. (updated by Yaoyu Yang)

#### 2015-11-09
* Image_plate protocol will now ask techs to choose the status of a plate: normal, lawn or contaminated and record this information in the data field of an item. This applies to the E coli plate of plasmid produced from Gibson Assembly, Yeast Plate produced from Yeast Transformation and Divided Yeast Plate produced from Streak Yeast Plate. (updated by Garrett Newman and Yaoyu Yang)
* Adding details about how to streak plate with better sterile technique based on staff meeting (updated by Garrett Newman)
