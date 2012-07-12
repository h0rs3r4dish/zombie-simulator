module ZedSim

class Map
	attr_reader :width, :height

	def initialize(width=80,height=24)
		@grid = Array.new(height).map { Array.new(width) }
		(0...height).each { |y| (0...width).each { |x|
			@grid[y][x] = Tile.new(:ground, [x,y])
		} }
		@width = width
		@height = height
	end

	def [](x,y)
		if y.class.to_s == "Fixnum" then
			@grid[y][x]
		elsif y.class.to_s == "Range" then
			y.to_a.map { |row| @grid[row][x] }
		end
	end
	def tiles_near(x,y,size)
		self[ Range.new((x-size).min(0),(x+size).max(@width - 1)), 
			  Range.new((y-size).min(0),(y+size).max(@height - 1)) ]
	end

	def each(&block); @grid.map &block; end
	def each(&block); @grid.each &block; end

	def to_a
		@grid.map { |row| row.map { |tile| tile.to_s }.join('') }
	end
	def to_s
		to_a.join("\n")
	end
end

class Tile
	SYMBOLS = {
		:ground => '.'
	}

	attr_reader :type, :location, :elevation
	attr_accessor :creature, :color, :items

	def initialize(type, coords, elevation=0)
		@type = type
		@location = coords
		@elevation = 0
		@creature = nil
		@color = :default

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

	def include_weapon?
		@items.each { |item| return true if item.type == :weapon }
		return false
	end

	def color
		return @creature.color unless @creature.nil?
		return @items.first.color unless @items.empty?
		return @color
	end
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
