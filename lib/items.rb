module ZedSim

class Item
	attr_reader :name, :type, :symbol, :color
	def initialize(name, type, symbol, color=:white)
		@name = name
		@type = type
		@symbol = symbol
		@color = color
	end
	def add_attr(*attributes)
		if attributes.first.class.to_s == "Hash" then
			attributes = attributes.first
			add_attr *attributes.keys
			attributes.each_pair { |key, val| self.send((key.to_s+'=').intern, val) }
		else
			attributes.each { |attribute|
				getter = "@#{attribute}"
				self.define_singleton_method attribute do
					instance_variable_get getter
				end
				self.define_singleton_method (attribute.to_s+'=').intern do |val|
					instance_variable_set getter, val
				end
			}
		end
	end

	def to_c; @symbol; end

	class << self
		WEAPON_TYPES = [
			[ "Machete", '/', 2..5, 0.8, 1 ],
			[ "Axe", '/', 5..10, 0.6, 1 ],
			[ "Pistol", '+', 5..10, 0.5, 4 ]
		]
		def new_weapon(name, symbol, damage, accuracy, range=1)
			weapon = self.new(name, :weapon, symbol)
			weapon.add_attr :damage => damage, :accuracy => accuracy, :range => range
			return weapon
		end

		def new_random_weapon
			new_weapon *WEAPON_TYPES.shuffle.first
		end
	end
end

end
