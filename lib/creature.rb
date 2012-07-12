require 'lib/patch/fixnum'

module ZedSim

class Creature
	SYMBOL = 'h'
	VISION_LENGTH = 7

	@@id = 0

	attr_reader :color
	attr_accessor :location, :status, :id, :facing

	def initialize(map, creature_list, location)
		@map = map
		@location = location
		@creature_list = creature_list
		@status = :alive
		@id = @@id += 1
		@facing = :north
		@color = :white

		@map[*@location].creature = self
	end

	def move_toward(target_x,target_y)
		dx = target_x - @location.first
		dy = target_y - @location.last
		step_x = if dx > 0 then
					 1
				 elsif dx < 0
					 -1
				 else
					 0
				 end
		step_y = if dy > 0 then
					 1
				 elsif dy < 0
					 -1
				 else
					 0
				 end

		new_facing = [ [ :northwest, :north, :northeast ],
			[ :west, nil, :east ],
			[ :southwest, :south, :southeast ] ][1 + step_y][1 + step_x]
		@facing = new_facing unless new_facing.nil?
		
		move_to @location.first + step_x, @location.last + step_y
	end
	def move_to(x,y)
		return unless @map[x,y].creature.nil?
		@map[*@location].creature = nil
		@map[x,y].creature = self
		@location = [x,y]
	end
	def move_along_facing
		dx = 0
		dy = 0
		s_facing = @facing.to_s
		dy = -1 if s_facing.include? 'north'
		dy = 1  if s_facing.include? 'south'
		dx = -1 if s_facing.include? 'west'
		dx = 1  if s_facing.include? 'east'
		move_toward (@location.first+dx).min(0).max(@map.width-1),
			(@location.last+dy).min(0).max(@map.height-1)
	end

	def line_of_sight
		vision = self.class.const_get :VISION_LENGTH
		case @facing
		when :north, :south
			(0..vision).to_a.map { |offset|
				@map[ (@location.first + ((@facing == :north) ? -offset : offset)).
					min(0).max(@map.height - 1),
					Range.new(
						(@location.last - offset).min(0),
						(@location.last + offset).max(@map.height - 1)
				) ]
			}.delete_if { |tile| tile.nil? }
		when :east, :west
			cols = (0..vision).to_a.map { |width|
				(
					([nil] * (vision - width)) +
					@map[
						@location.first + ((@facing == :west) ? -width : width).
							min(0).max(@map.width - 1),
						Range.new(
							(@location.last - width).min(0),
							(@location.last + width).max(@map.height - 1) )

					] +
					([nil] * (vision - width))
				).flatten
			} # gives an array of cols (that is, vertical slices)
			longest = 0; cols.each { |row|
				longest = row.length if longest < row.length
			}
			rows = Array.new(longest).map { Array.new }
			cols.each_with_index { |row, x| row.each_with_index { |tile, y|
				rows[y][x] = tile
			} }
			rows.map { |col| col.delete_if { |tile| tile.nil? } }
		when :northeast, :northwest, :southeast, :southwest
			x_range = Range.new( @location.first, (@location.first + (
				(@facing.to_s.include? 'south') ? -vision : vision)).min(0).max(
					@map.width - 1) )
			y_range = Range.new( @location.last, (@location.last + (
				(@facing.to_s.include? 'west') ? -vision : vision)).min(0).max(
					@map.height - 1) )
			@map[x_range,y_range]
		end
	end

	def remove_self
		@map[*@location].creature = nil
		@creature_list.delete self
	end

	def distance_from(other)
		log "Evaluating #{other.inspect} (locaiton: #{other.location.inspect}"
		Math.sqrt(
			(@location.first - other.location.first) ** 2 +
			(@location.last  - other.location.last) ** 2
		)
	end

	def tick; end

	def to_c; self.class.const_get :SYMBOL; end
end

end
