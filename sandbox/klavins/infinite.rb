# infinite loop to test robustness of krill server

class Protocol

	def main

		show {
			title "One"
		}

		loop do
			sleep 1.0
		end

		show {
			title "Two"
		}


	end

end