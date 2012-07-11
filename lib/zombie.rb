require 'lib/creature' 

module ZedSim

class Zombie < Creature
	SYMBOL = 'Z'
	VISION_LENGTH = 5

	MOVEMENT_RATE = 0.75
	MOVEMENT_NEEDED = 1

	def initialize(map, creature_list, location, human_source=nil)
		super map, creature_list, location
		@status = :zombie
		@movement = 0
	end

	def tick
		@movement += MOVEMENT_RATE
		return unless @movement > MOVEMENT_NEEDED
		@movement -= MOVEMENT_NEEDED

		touchable_human = @map.tiles_near(*@location, 1).flatten.map { |tile|
			tile.creature }.delete_if { |val| val.nil? }.select { |creature|
			creature.status == :alive }.shuffle.first

		unless touchable_human.nil? then
			attack touchable_human
			return
		end

		nearest_human = line_of_sight.flatten.map { |tile| tile.creature }.
			delete_if { |tile| tile.nil? }.select { |creature|
			creature.status == :alive }.sort { |a, b|
			distance_from(a) <=> distance_from(b) }.first

		if nearest_human.nil? then
			coinflip = rand 4 # 0 = no move, 1-2 = follow @facing, 3 = random
			return if coinflip == 0
			if coinflip == 3 then
				move_toward rand(@map.width), rand(@map.height)
				return
			end
			dx = 0
			dy = 0
			s_facing = @facing.to_s
			dy = -1 if s_facing.include? 'north'
			dy = 1  if s_facing.include? 'south'
			dx = -1 if s_facing.include? 'west'
			dx = 1  if s_facing.include? 'east'
			move_toward (@location.first+dx).min(0).max(@map.width-1),
				(@location.last+dy).min(0).max(@map.height-1)
		else
			move_toward *nearest_human.location
		end
	end

	def attack(human)
		human.status = :infected
	end
end

end
