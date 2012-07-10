require 'lib/patch/fixnum'

module ZedSim

class Creature
	SYMBOL = 'h'
	@@id = 0

	attr_accessor :location, :status, :id

	def initialize(map, creature_list, location)
		@map = map
		@location = location
		@creature_list = creature_list
		@status = :alive
		@id = @@id += 1
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

end
