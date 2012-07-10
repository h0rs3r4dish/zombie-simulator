require 'lib/patch/fixnum'

module ZedSim

class Creature
	SYMBOL = 'h'

	attr_accessor :location, :status

	def initialize(map, creature_list, location)
		@map = map
		@location = location
		@creature_list = creature_list
		@status = :alive
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
		move_to @location.first + step_x, @location.last + step_y
	end
	def move_to(x,y)
		return unless @map[x,y].creature.nil?
		@map[*@location].creature = nil
		@map[x,y].creature = self
		@location = [x,y]
	end

	def tick; end

	def to_c; self.class.const_get :SYMBOL; end
end

class Human < Creature
	def tick
		if @status == :infected then
			turn_to_zombie
			return
		end
		@objective = [rand(80),rand(24)] if @objective.nil? or @location == @objective
		move_toward *@objective
	end

	def turn_to_zombie
		zed = Zombie.new(@map, @creature_list, @location, self)
		@creature_list.delete self
		@creature_list.push zed
		@map[*@location].creature = zed
	end
end

class Zombie < Creature
	SYMBOL = 'Z'

	def initialize(map, creature_list, location, human_source=nil)
		super map, creature_list, location
		@status = :zombie
	end

	def tick
		x_range = Range.new((@location.first-1).min(0),(@location.first+1).max(79))
		y_range = Range.new((@location.last-1).min(0),(@location.last+1).max(23))
		human = (
			@map[x_range,y_range].flatten.map { |tile| tile.creature } - [ nil ]
		).select { |creature| creature.status == :alive }.first

		if human.nil? then
			@objective = [rand(80),rand(24)] if @objective.nil? or @objective == \
				@location
			move_toward *@objective
		else
			attack human
		end
	end

	def attack(human)
		human.status = :infected
	end
end

end
