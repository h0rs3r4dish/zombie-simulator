require 'lib/patch/fixnum'
require 'lib/line'

module ZedSim

class Creature
	SYMBOL = 'h'
	VISION_LENGTH = 7

	@@id = 0

	attr_reader :color, :condition
	attr_accessor :location, :status, :id, :facing

	def initialize(map, creature_list, location)
		@map = map
		@location = location
		@creature_list = creature_list
		@status = :alive
		@id = @@id += 1
		@facing = :north
		@color = :white
		@condition = { 
			:bleeding => false, :health => 10, :infected => false
		}.to_struct

		@map[*@location].creature = self
	end

	def move_to(target_x,target_y)
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

		log_self "moving from #{@location.join(',')} to #{target_x},#{target_y}"
		return false unless movable_directions.include? new_facing
		return false unless @map[target_x, target_y].creature.nil?
		log_self "has been cleared for movement"

		@facing = new_facing
		@map[*@location].creature = nil
		@map[target_x, target_y].creature = self
		@location = [target_x, target_y]
		return true
	end

	def move_toward(coords)
		@line = Line.new(@location => coords) if @line.nil? or coords != @line.to
		move_along_line
	end
	def move_along_line
		success = move_to *@line.step
		@line.undo unless success
	end
	def move_along_facing
		dx = 0
		dy = 0
		s_facing = @facing.to_s
		dy = -1 if s_facing.include? 'north'
		dy = 1  if s_facing.include? 'south'
		dx = -1 if s_facing.include? 'west'
		dx = 1  if s_facing.include? 'east'
		move_to (@location.first+dx).min(0).max(@map.width-1),
			(@location.last+dy).min(0).max(@map.height-1)
	end
	def movable_directions
		log_self "checking valid directions from #{@location}, map size: #{
			@map.width}x#{@map.height}"
		banned_directions = Array.new
		if @location.first == 0 then
			[:west, :northwest, :southwest].each { |dir|
				banned_directions << dir
			}
		elsif @location.first >= @map.width-1 then
			[:east, :northeast, :southeast].each { |dir|
				banned_directions << dir
			}
		end
		if @location.last == 0 then
			[:north, :northwest, :northeast].each { |dir|
				banned_directions << dir
			}
		elsif @location.last >= @map.height-1 then
			[:south, :southwest, :southeast].each { |dir|
				banned_directions << dir
			}
			end
		log_self "can't move #{banned_directions.join(', ')}"
		allowed= [ :north, :northeast, :east, :southeast, :south, :southwest, :west,
			:northwest ] - banned_directions
		log_self "can move #{allowed.join(', ')}"
		return allowed
	end

	def line_of_sight
		vision = self.class.const_get :VISION_LENGTH
		(case @facing

		when :north, :south
			(0..vision).to_a.map { |width|
				@map[
					Range.new(
						(@location.first - width).min(0),
						(@location.first + width).max(@map.width - 1),
					),
					(@location.last + ((@facting == :north) ? -width : width)).
						min(0).max(@map.height - 1),
				 ]
			}
		when :east, :west
			cols = (0..vision).to_a.map { |width|
				@map[
					(@location.first + ((@facing == :west) ? -width : width)).
						min(0).max(@map.width - 1),
					Range.new(
						(@location.last - width).min(0),
						(@location.last + width).max(@map.height - 1) )

				]
			}
		when :northeast, :northwest, :southeast, :southwest
			x_range = Range.new( @location.first, (@location.first - (
				(@facing.to_s.include? 'west') ? -vision : vision)).min(0).max(
					@map.width - 1) )
			y_range = Range.new( @location.last, (@location.last - (
				(@facing.to_s.include? 'south') ? -vision : vision)).min(0).max(
					@map.height - 1) )
			@map[x_range,y_range]

		end).flatten
	end

	def alert(loc, type=nil); end
	def alert_in_area(loc, radius, filter, type=nil)
		@map.tiles_near(*@location, radius).flatten.each { |tile|
			creature = tile.creature
			next if creature.nil?
			if filter.class.to_s == "Array" then
				next unless filter.include? creature.status
			else
				next unless creature.status == filter
			end
			creature.alert loc, type
		}
	end

	def damage(n)
		@condition.bleeding = true
		@condition.health -= n
		die if @condition.health < 1
	end
	def bleed
		@condition.bleeding = false if rand(5) == 0
		@map[*@location].color = :bright_red
	end
	def die
		log_self "has died"
		remove_self
		corpse = Item.new("Corpse of ##{@id.to_s 16}", :corpse, "%", @color)
		@map[*@location].items << corpse
	end
	def remove_self
		@map[*@location].creature = nil
		@creature_list.delete self
		return unless [:alive, :zombie].include? @status
		list = if @status == :alive then
				   :humans
			   else
				   :zombies
			   end
		@creature_list.count[list] -= 1
		log_self "removed from the creature list, #{@creature_list.count[list]} #{
			list} remaining"
	end

	def distance_from(other)
		Math.sqrt(
			(@location.first - other.location.first) ** 2 +
			(@location.last  - other.location.last) ** 2
		)
	end

	def tick; end

	def log_self(str)
		log "##{@id.to_s 16} #{str}"
	end
	def to_c; self.class.const_get :SYMBOL; end
end

end
