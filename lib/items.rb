module ZedSim

class Item
	attr_reader :name, :symbol
	def initialize(name, symbol)
		@name = name
		@symbol = symbol
	end
	def to_c; @symbol; end
end

class Weapon < Item
	attr_reader :range, :accuracy, :damage
	def initialize(name, range, accuracy, damage)
		super name, ((range > 1) ? '+' : '/')
		@range = range
		@accuracy = accuracy
		@damage = damage
	end

	class << self
		def generate
			self.new("Machete", 1, 1.0, 100)
		end
	end
end

end
