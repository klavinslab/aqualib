class Protocol

	def arguments
		{
			a: 1,
			b: "banana"
		}
	end

	def main
		a, b = input[:a], input[:b]
		show {
			note a
			note b
		}
	end

end
