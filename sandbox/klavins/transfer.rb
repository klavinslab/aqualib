class Protocol

	def main

		#samples = SampleType.where("name='Fragment'")[0].samples
		samples = find(:sample,sample_type: {name: 'Fragment'})

		x = (produce spread samples[0,25], "Stripwell", 1, 12)[0]
		y = produce new_collection "Gel", 2, 6

		routing = [
			{ from: [0,0], to: [0,0], volume: 10 },
			{ from: [0,1], to: [1,1] },
			{ from: [0,2], to: [1,3] },
			{ from: [0,3], to: [0,3] },
			{ from: [0,4], to: [1,4] },
			{ from: [0,4], to: [1,5] }		
		]

		show do
			title "Transfer"
			transfer x, y, routing
		end

		release [x, y]

	end

end
