module ZedSim

class Item
	attr_reader :name, :type, :symbol
	def initialize(name, type, symbol)
		@name = name
		@type = type
		@symbol = symbol
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
		def new_weapon(name, symbol, accuracy)
			weapon = self.new(name, :weapon, symbol)
			weapon.add_attr :accuracy => accuracy
			return weapon
		end
	end
end

end
