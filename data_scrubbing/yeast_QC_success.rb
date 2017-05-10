class Protocol
	def arguments
		{
			id_bounds: [20000, 20500]
			# 22640
			# 40125
		}
	end

	def main
		# Find Primer Orders
		yeast_QC_prot_id = TaskPrototype.where(name: "Yeast Strain QC").first.id
		tasks = Task.where({task_prototype_id: yeast_QC_prot_id, id: input[:id_bounds].first..input[:id_bounds].last})
		
		puts "TASKS FETCHED\n-------------"
		puts "#{tasks.length} Yeast Strain QC tasks"

		# Build hash for each task
		task_hashes = tasks.map do |task|
			puts "task #{task.id}"
			# yeast_plates
			yeast_plate_ids = task.simple_spec[:yeast_plate_ids]
			yeast_plates = Item.where(id: yeast_plate_ids)
			puts "	yeast plates: #{yeast_plate_ids}"

			# QC_results
			qc_results = yeast_plates.map { |yp| yp.datum[:QC_result] }.flatten
			puts "	QC results: #{qc_results}"

			# marker
			yeast_sample = yeast_plates.first.sample
			markers = yeast_sample.properties("Integrated Marker(s)")
			puts "	markers: #{markers}"

			{ task: task, yeast_plates: yeast_plates, QC_results: qc_results, markers: markers }
		end

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