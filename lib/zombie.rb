module ZedSim

class Zombie < Creature
	SYMBOL = 'Z'
	MOVEMENT_RATE = 0.75
	MOVEMENT_NEEDED = 1

	def initialize(map, creature_list, location, human_source=nil)
		super map, creature_list, location
		@status = :zombie
		@movement = 0
	end

	def tick
		nearest_human = (@map.tiles_near(*@location, 1).flatten.map { |tile|
			tile.creature } - [nil]).select { |creature| creature.status == :alive }.first
		unless nearest_human.nil? then
			attack nearest_human
			@objective = nil
			return
		end
		@movement += MOVEMENT_RATE
		return unless @movement > MOVEMENT_NEEDED
		@movement -= MOVEMENT_NEEDED
		if @objective.nil? then
			range = 2
			max_range = 5
			while nearest_human.nil?
				if range > max_range then
					move_toward rand(@map.width), rand(@map.height)
					return
				end
				nearest_human = (@map.tiles_near(*@location, range).flatten.map { |tile|
					tile.creature } - [nil]).select { |creature|
					creature.status == :alive }.shuffle.first
				range += 1
			end
			@objective = nearest_human
		else
			move_toward *@objective.location
			@objective = nil if @objective.status != :alive
		end
	end

	def attack(human)
		human.status = :infected
	end
end

end
