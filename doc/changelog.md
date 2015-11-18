Aquarium Klavins Lab Cloning Workflow
===
Change Log
---
#### 2015-11-17
* Yeast plates and divided yeast plates that are longer than 110 days (will be changed to 90 days a few weeks later) will be automatically submitted to Discard Item task and will be deleted when techs run the Discard Item workflow every day. If you don't want particular old plate to be deleted, in the item data field, write "keep_item": "Yes". (updated by Yaoyu Yang)
* Gibson Assembly will now take the oldest fragment stock (i.e. fragment stock with lowest item id) if there are multiple fragment stocks in the inventory. It used to take the newest stock based on some people's feedbacks but David Younger insists we should take the oldest fragment stock. (updated by Yaoyu Yang)

#### 2015-11-16
* Fragment Construction workflow will now produce multiple fragment stocks for the same fragments. It used to only produce one fragment stock even you submit multiple of the same fragments but now changed. Just submit multiple tasks for making the same fragment stocks or in one task enter the same fragment id multiple times. This improvement should help us producing more of the backbone fragment stocks that constantly used and running out in the Gibson Assembly. (updated by Yaoyu Yang)

#### 2015-11-13
* A smart and fair algorithm is implemented to determine which tasks to run when the tech capacity, total number of tasks the tech can run everyday, is lower than the number of tasks in the queue. Under this new algorithm, each user in the queue is guaranteed to have a quota of tasks to be run by the workflow. The quota is simply determined by the tech capacity and number of users in the queue. The remaining capacity after fulfilling each user's quota will be prorated among the remaining users until not able to be prorated and then the leftover capacity will be used to fulfill tasks sequentially. (updated by Yaoyu Yang)

#### 2015-11-09
* Image_plate protocol will now ask user to choose the status of a plate: normal, lawn or contaminated and record this information in the data field of an item. This applies to the E coli plate of plasmid produced from Gibson Assembly, Yeast Plate produced from Yeast Transformation and Divided Yeast Plate produced from Streak Yeast Plate. (updated by Garrett Newman and Yaoyu Yang)
* Adding details about how to streak plate with better sterile technique based on staff meeting (updated by Garrett Newman)