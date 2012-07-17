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
			{ :name => "Machete", :damage => 2..5, :accuracy => 0.8, :range => 1 },
			{ :name => "Axe", :damage => 5..10, :accuracy => 0.6, :range => 1 },
			{ :name => "Pistol", :damage => 5..10, :accuracy => 0.3, :range => 4,
				:other => { :ammo_type => :'9mm', :ammo_count => 10} }
		]
		AMMO_TYPES = [
			{ :name => "9mm ammo", :size => :'9mm', :count => 5..15 }
		]
		def new_weapon(name, symbol, damage, accuracy, range=1, attr=nil)
			weapon = self.new(name, :weapon, symbol)
			weapon.add_attr :damage => damage, :accuracy => accuracy, :range => range
			weapon.add_attr attr unless attr.nil?
			return weapon
		end
		def new_ammo(name, size, count)
			ammo = self.new(name, :ammo, '=')
			ammo.add_attr :size => size, :count => count
			return ammo
		end

		def new_random_weapon
			spec = WEAPON_TYPES.shuffle.first
			new_weapon(spec[:name], (spec[:range] > 1) ? '+' : '/', spec[:damage],
					   spec[:accuracy], spec[:range], spec[:other])
		end
		def new_random_ammo
			spec = AMMO_TYPES.shuffle.first
			new_ammo spec[:name], spec[:size], rand_range(spec[:count])
		end
	end
end

end
