require_relative 'tile'

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

end
