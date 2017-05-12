class Protocol
	def arguments
		{
			id_bounds: [20000, 20500],
			id_interval: 35000
			# 22640
			# 40125
		}
	end

	def main
		# Loop through ranges offset by id_interval
		iterations = ((input[:id_bounds].last - input[:id_bounds].first) / input[:id_interval].to_f).ceil

		iterations.times do |i|
			# Calculate range
			range_bottom = input[:id_bounds].first + input[:id_interval] * i
			range_top = input[:id_bounds].first + input[:id_interval] * (i + 1)
			range_top = input[:id_bounds].last if range_top > input[:id_bounds].last
			range = range_bottom..range_top

			# Find Yeast Strain QCs
			yeast_QC_prot_id = TaskPrototype.where(name: "Yeast Strain QC").first.id
			tasks = Task.where({ task_prototype_id: yeast_QC_prot_id, id: range })
			
			puts "\nTASKS FETCHED\n-------------"
			puts "#{tasks.length} Yeast Strain QC tasks"

			# Build hash for each task
			task_hashes = tasks.map do |task|
				puts "\ntask #{task.id}";
				# yeast_plates
				yeast_plate_ids = task.simple_spec[:yeast_plate_ids];
				yeast_plates = Item.where(id: yeast_plate_ids);
				puts "	yeast plates: #{yeast_plate_ids}";

				# QC_results
				qc_results = yeast_plates.map { |yp| yp.datum[:QC_result] }.flatten;
				puts "	QC results: #{qc_results}";

				# marker
				yeast_sample = yeast_plates.first.sample;
				markers = yeast_sample.properties["Integrated Marker(s)"];
				puts "	markers: #{markers}";

				{ task: task, yeast_plates: yeast_plates, QC_results: qc_results, markers: markers };
			end

			# Build QC success frequency for TRP plates
			task_hashes_trp = task_hashes.select { |th| th[:markers].downcase.include? "trp" }
			task_hashes_trp.reject! { |th| th[:QC_results].include?(nil) || th[:QC_results].include?("N/A") }
			trp_success = task_hashes_trp.map { |th| { date: th[:task].created_at, success: th[:QC_results].count { |r| r == "Yes" }.to_f / th[:QC_results].length } }
			
			# Print to show blocks
			show do
				title "Copy this into excel (col 1) :) (range #{range.first}-#{range.last})"

				trp_success.each do |hash|
					# time = hash[:date]
					# excel_time = Time.at(time.to_f + time.utc_offset)
					note hash[:date].strftime("%m/%d/%Y")
				end
			end

			show do
				title "Copy this into excel as well (col 2) :) (range #{range.first}-#{range.last})"

				trp_success.each do |hash|
					note hash[:success]
				end
			end
		end
	end
end