require 'lib/patch/fixnum'

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
		step_coords = [@location.first + step_x, @location.last + step_y]

		unless @map[*step_coords].passable? then
			near_loc  = @map.tiles_near(*step_coords, 1).flatten
			near_self = @map.tiles_near(*@location, 1).flatten
			alternatives = Array.new
			near_self.each { |s_tile| near_loc.each { |l_tile|
					alternatives << s_tile.location if s_tile.location == l_tile.location
			} }
			alternatives.shuffle.each { |alt|
				if @map[*alt].passable? then
					step_coords = alt
					break
				end
			}
		end

		new_facing = [ [ :northwest, :north, :northeast ],
			[ :west, nil, :east ],
			[ :southwest, :south, :southeast ] ][1 + step_y][1 + step_x]
		@facing = new_facing unless new_facing.nil?
		
		move_to *step_coords
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
	def movable_directions
		banned_directions = Array.new
		if @location.first == 0 then
			banned_directions << :west
		elsif @location.first == @map.width - 1 then
			banned_directions << :east
		end
		if @location.last == 0 then
			banned_directions << :north
			banned_directions << :northwest if banned_directions.include? :west
			banned_directions << :northeast if banned_directions.include? :east
		elsif @location.last == @map.height - 1 then
			banned_directions << :south
			banned_directions << :southwest if banned_directions.include? :west
			banned_directions << :southeast if banned_directions.include? :east
		end
		return [ :north, :northeast, :east, :southeast, :south, :southwest, :west,
			:northwest ] - banned_directions
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
