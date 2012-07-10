class Fixnum
	def min(n)
		(self < n) ? n : self
	end
	def max(n)
		(self > n) ? n : self
	end
end
