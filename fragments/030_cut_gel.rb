class Protocol

	def main

		gels = take input[:gel_ids].collect { |i| collection_from i }

		show {
			title "Retrieve Gels"
			note "Get the gels with ids #{gels.collect { |g| g.id }}"
		}

	end

end