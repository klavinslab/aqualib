class Protocol

	def main
		data = show {
			title "An input example"
			get "text", var: "y", label: "Enter a string", default: "Hello World 1"
			get "text", var: "z", label: "Enter a string", default: "Hello World 2"
		}

	y = data[:y]
	z = data[:z]

	show {
		note y
		note z
	}

	end
end
