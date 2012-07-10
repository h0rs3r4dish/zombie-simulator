module ZedSim

class Map
	attr_reader :width, :height

	def initialize(width=80,height=24)
		@grid = Array.new(height).map { Array.new(width) { Tile.new(:ground) } }
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

	def each(&block); self.to_a.each &block; end
	def each(&block); self.to_a.each &block; end

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

	attr_reader :type, :elevation, :items
	attr_accessor :creature

	def initialize(type, elevation=0)
		@type = type
		@elevation = 0
		@creature = nil
		@items = []
	end

	def to_s
		return @creature.to_c unless @creature.nil?
		return @items.first.to_c unless @items.empty? 
		return SYMBOLS[@type]
	end
end

end
