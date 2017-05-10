class Protocol
	def arguments
		{
			id_bounds: [20000, 20125]
			# 22640
			# 40125
		}
	end

	def main
		# Find Primer Orders
		yeast_QC_prot_id = TaskPrototype.where(name: "Yeast Strain QC").first.id
		# tasks_response = Test.send({
		#   login: Test.login,
		#   key: Test.key,
		#   run: {
		#     method: "find",
		#     args: {
		#       model: :task,
		#       where: { id: lower_bound_id..upper_bound_id,
		#       		   task_prototype_id: yeast_QC_prot_id }
		#     }
		#   }
		# })
		# tasks = tasks_response[:rows]
		puts "TASKS FETCHED..."
		tasks = Task.where({task_prototype_id: yeast_QC_prot_id, id: io_hash[:id_bounds]})
		puts tasks.length
		puts tasks.map { |t| t.id }
		# puts tasks

		# # Build hash for each task
		# task_hashes = tasks.map do |task|
		# 	# yeast_plates
		# 	yeast_plate_ids = task[:specification][/\[(.*?)\]/, 1].split(',').map { |id| id.to_i }

		# 	plate_response = Test.send({
		# 	  login: Test.login,
		# 	  key: Test.key,
		# 	  run: {
		# 	    method: "find",
		# 	    args: {
		# 	      model: :item,
		# 	      where: { id: yeast_plate_ids }
		# 	    }
		# 	  }
		# 	})
		# 	yeast_plates = plate_response[:rows]

		# 	# QC_results
		# 	qc_results = yeast_plates.map { |yp| yp[:data][:QC_result] }.flatten

		# 	# marker
		# 	yeast_sample_id = yeast_plates.first[:sample_id]
		# 	sample_response = Test.send({
		# 	  login: Test.login,
		# 	  key: Test.key,
		# 	  run: {
		# 	    method: "find",
		# 	    args: {
		# 	      model: :sample,
		# 	      where: { id: yeast_sample_id }
		# 	    }
		# 	  }
		# 	})
		# 	yeast_sample = sample_response[:rows].first
		# 	markers = yeast_sample[:fields][:"Integrated Marker(s)".to_sym]
		# 	puts yeast_sample.keys

		# 	{ task: task, yeast_plates: yeast_plates, QC_results: qc_results, markers: markers }
		# end

		# task_hashes.select.each do |task_hash|
		# 	task = task_hash[:task]
		# 	puts "Task #{task[:id]}: #{task[:name]}"
		# 	puts "  date: #{task[:updated_at]}"
		# 	puts "  yeast plate ids: #{task_hash[:yeast_plates].map { |yp| yp[:id] }}"
		# 	puts "  QC_results: #{task_hash[:QC_results]}"
		# 	puts "  marker: #{task_hash[:markers]}"
		# end


		# # Calculate average Primer cost
		# short_primer_cost = Parameter.get_float('short primer cost')
		# medium_primer_cost = Parameter.get_float('medium primer cost')
		# long_primer_cost = Parameter.get_float('long primer cost')

		# primer_costs = primer_lengths.map { |length|
		#   if length <= 60
		#     length * short_primer_cost
		#   elsif length <= 90
		#     length * medium_primer_cost
		#   else
		#     length * long_primer_cost
		#   end
		# }

		# average_cost = primer_costs.inject { |sum, cost| sum + cost }.to_f / primer_costs.length

		# puts "There are #{tasks.length} Primer Orders"
		# puts "There are #{primers_response[:rows].length} Primers"
		# puts "The average Primer cost is $#{average_cost.round(2)}"
	end
end