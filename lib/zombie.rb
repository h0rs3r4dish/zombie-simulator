require 'lib/creature' 
require 'lib/items'
require('lib/extra/markers') if CONFIG[:markers]

module ZedSim

class Zombie < Creature
	SYMBOL = 'Z'

	MOVEMENT_RATE = 0.60
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
		@condition.infected = true
	end

	def tick
		@movement += MOVEMENT_RATE
		return unless @movement > MOVEMENT_NEEDED
		@movement -= MOVEMENT_NEEDED

		bleed if @condition.bleeding

		touchable_human = @map.tiles_near(*@location, 1).flatten.map { |tile|
			tile.creature }.delete_if { |val| val.nil? }.select { |creature|
			creature.status == :alive and creature.condition.infected == false }.
			shuffle.first

		unless touchable_human.nil? then
			attack touchable_human 
			return
		end

		nearest_human = line_of_sight.flatten.map { |tile| tile.creature }.
			delete_if { |tile| tile.nil? }.select { |creature|
			creature.status == :alive }.sort { |a, b|
			distance_from(a) <=> distance_from(b) }.first

		if nearest_human.nil? then
			unless @objective.nil? then
				if @location != @objective then
					move_toward *@objective
					return
				else
					@objective = nil
				end
			end
			case rand(4) # 0 = no move, 1-2 = follow @facing, 3 = random
			when 0
				return
			when 3
				move_toward rand(@map.width), rand(@map.height)
			else
				move_along_facing
			end
		else
			move_toward *nearest_human.location
		end
	end

	def attack(human)
		alert_in_area human.location, 7, :zombie
		if rand(2) == 0 then
			dmg = rand_range 1..4
			log_self "bit ##{human.id.to_s 16} for #{dmg} damage"
			human.damage dmg
			human.infect if rand(3) == 0
		end
	end
	def alert(loc, type=nil)
		@objective = loc
	end
end


end
