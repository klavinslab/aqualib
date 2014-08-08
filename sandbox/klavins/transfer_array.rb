class Protocol

	def main

		samples = find(:sample,sample_type: {name: 'Fragment'})
		ladders = find(:item,sample:{name:"1 kb Ladder"})

		x = (produce spread samples[0,25], "Stripwell", 1, 12)[0]
		y1 = produce new_collection "Gel", 2, 3
		y2 = produce new_collection "Gel", 2, 3
		y3 = produce new_collection "Gel", 2, 3

		y1.set 0, 0, ladders[0]
		y2.set 0, 0, ladders[0]
		y3.set 0, 0, ladders[0]

		transfer( [x], [y1, y2, y3] ) {
			note "Be careful to transfer each well exactly as specified."
		}

		release [x, y1, y2, y3]

	end

end
