class Protocol

	def main

		gels = take input[:gel_ids].collect { |i| collection_from i }

		show {
			title "Retrieve Gels"
			note "Get the gels with ids #{gels.collect { |g| g.id }}"
		}

		show {
			title "TODO"
			note "Describe how to slice the gels here"
		}

		slices = []

		gels.each do |gel|

			s = distribute( gel, "Gel Slice", except: [ [0,0], [1,0] ], interactive: true ) {
				title "Cut gel slices and place them in new 1.5 mL tubes"
				note "Label the tubes with the id shown"
			}

			produce s

			slices = slices.concat s

		end

		release slices, interactive: true, method: "boxes"

	end

end