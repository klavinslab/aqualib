class Protocol

	# always set debug to ture???	
	def debug
		true
	end

	#use http://54.68.9.194/

	def main
		# allObjects = get allobjects
		object_types = ObjectType.all # collection?
		object_types_to_check = []

		object_types.each do |object_type|
			if /\{.*\}/.match(object_type.data) #to avoid default "No Data"
				data_in_JSON = JSON.parse(object_type.data) 
				if data_in_JSON["inventory_check"] # == "true" 
					object_types_to_check.push object_type
					min_volume = data_in_JSON["min_volume"]  ###  with units !!!
					object_name = object_type.name
					object_instances = find(:item, object_type: { name: object_name })
					#object_instances = find(:item, object_type: { name: "Enzyme Stock" })
					#  # count of instance / min number of instance 
					instance_count = object_instances.size 
					min_count = 9999999 # in JSON later

					object_instances.each do |object_instance|
						#instance_volume = object_instance. #??? 
						instance_volume = 3 
						#if need to discard items
						if instance_volume < min_volume
							# if need to order more of some type
							show{
								#must use to_s for numbers otherwise converted to ASCII
								note object_type.name << " ID : " << object_instance.id << " has volume less than " << min_volume.to_s 
								note "Please discard"
							}
							object_instance.mark_as_deleted
						end
					end

					if instance_count < min_count 
						# if need to order more of some type
						show{
							#must use to_s for numbers otherwise converted to ASCII
							note object_type.name << " current count : " << instance_count.to_s 
							note "the required min number is " << min_count.to_s
							note "Please plan to order more"
						}
					end

						# show {
						# 	note instance_count
						# 	note object_instances.collect { |i| i.datum.to_s }
						# }
				end
			end	
		end

		show {
			note object_types_to_check.collect { |o| o.name }
		}
		

		# EEROR executed too many steps (50)  ??? 
		# specify which type to check? 




# item.datum




		# for each objectType in allobjcects
		# objectTypes.each do |objectType|
		# # 	if objectType.inventoryCheck #done by found
		# # 		currentCount = objectType.get_current_Count_from_database
		# 		currentCount = objectType.num_samples #Returns the number of non empty slots in the matrix.
		# 		#if currentCount < objectType.min
		# 		if condition < objectType.min 		 
		# # 			order more objectType 
		# #          (gernerate order task???) 
		# 			show{
		# 				#Objectype XXX has inventory count XXX
		# 				#Please order at least XXX amount to reach the min limt of XXX
		# 				note 
		# 			}
		# 		else 
		# # 			allInstance = get_all_instance_of_object_type
		# 			allInstance =objectType.m  #what's the matrix like???
		# 			objectType.dimensions
		# 			col.non_empty_string 
		# # 			for each instance in allInstance
		# # 				if (instance.volume < objectType.minVolume)
		# # 					throw the instance away (gernerate discard task???)
		# 				show{
		# 					#please discard item #XXX for objectType XXX 
		# 				}
  # 				end
		# end
	end
end