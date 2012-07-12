require 'lib/creature' 
require 'lib/items'

module ZedSim

class Zombie < Creature
	SYMBOL = 'Z'

	MOVEMENT_RATE = 0.75
	MOVEMENT_NEEDED = 1

	def initialize(map, creature_list, location, human_source=nil)
		super map, creature_list, location
		@status = :zombie
		@movement = 0
		@color = :green
		unless human_source.nil? then
			@facing = human_source.facing
			@map[*@location].items << human_source.pack.weapon unless human_source.
				pack.weapon.nil?
			human_source.pack.equipment.each { |item|
				@map[*@location].items << item }
		end
	end

	def tick
		@movement += MOVEMENT_RATE
		return unless @movement > MOVEMENT_NEEDED
		@movement -= MOVEMENT_NEEDED

		touchable_human = @map.tiles_near(*@location, 1).flatten.map { |tile|
			tile.creature }.delete_if { |val| val.nil? }.select { |creature|
			creature.status == :alive }.shuffle.first

		unless touchable_human.nil? then
			touchable_human.infect
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
			move_along_facing
		else
			move_toward *nearest_human.location
		end
	end

	def die
		@creature_list.delete self
		corpse = Item.new("Corpse", :body, "%")
		tile = @map[*@location]
		tile.items << corpse
		tile.creature = nil
	end

end

end
