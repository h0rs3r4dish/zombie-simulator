module ZedSim

class Tile
	SYMBOLS = {
		:ground => '.'
	}

	attr_reader :type, :location, :elevation
	attr_accessor :creature, :color, :items

	def initialize(type, coords, passable=true, elevation=0)
		@type = type
		@location = coords
		@passable = passable
		@elevation = 0
		@creature = nil
		@color = :bright_gray

		@items = []
		def @items.pop_weapon
			self.each_with_index { |item, i|
				if item.type == :weapon then
					self.delete_at i
					return item
				end
			}
		end
	end

	def filter_items(type)
		@items.select { |item| item.type == type }
	end
	def passable?
		(@creature.nil?) ? @passable : false
	end

	def method_missing(name, *args)
		name = name.to_s
		if name =~ /include_(\w*)\?/ then
			return filter_items($1.intern).length > 0
		end
	end

	def color
		return @creature.color unless @creature.nil?
		return @items.first.color unless @items.empty?
		return @color
	end
	def base_color; @color; end
	def to_s
		return @creature.to_c unless @creature.nil?
		return @items.first.to_c unless @items.empty? 
		return SYMBOLS[@type]
	end
	def inspect
		"#<Tile @location=#{@location.inspect} @creature=#{@creature.inspect} @items=#{
			@items.inspect}>"
	end
end

end
