class Hash
	def to_struct
		class << self
			def method_missing sym, *args
				s_sym = sym.to_s
				if s_sym.include? '=' then
					self[s_sym.sub('=','').intern] = args.first
				else
					self[sym]
				end
			end
		end
		self
	end
end
