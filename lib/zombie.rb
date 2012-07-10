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

		nearest_human = ((line_of_sight.flatten.delete nil).map { |tile| tile.creature }.
			delete nil).select { |creature| creature.status == :alive }.sort { |a, b|
				distance_from(a) <=> distance_from(b) }.first

		if distance_from nearest_human < 2 then
			attack nearest_human
		else
			move_towards nearest_human.location
		end
	end

	def attack(human)
		human.status = :infected
	end
end

end
