require 'lib/creature'
require 'lib/patch/hash'

module ZedSim

class Human < Creature
	def initialize(*args)
		super *args

		@pack = {
			:weapon => nil,
			:equipment => []
		}.to_struct

		@brain = Hash.new.to_struct
		@brain.directions = { :north => 0, :east => 0, :south => 0, :west => 0,
			:northeast => 0, :southeast => 0, :southwest => 0, :northwest => 0 }

		@brain.personality = [
			[:stupid, :smart].shuffle.first,
			[:aggressive, :cowardly].shuffle.first
		]
		
		@brain.objectives = Array.new
	end

	def tick
		if @status == :infected then
			log "##{@id} infection level #{@brain.infection}"
			@brain.infection -= 1
			@map[*@location].color = :bright_red if rand(3) != 2
			if @brain.infection == 0
				turn_to_zombie
				return
			end
		end

		weight = {
			:zombie => -1,
			:human  => (@brain.personality.include? :smart) ? 1 : 0,
			:weapon => (((@brain.personality.include? :aggressive) ? 1 : 0) +
				((@pack.weapon.nil?) ? 1 : 0))
		}

		# Attack if there's a weapon and a zombie within arm's reach
		unless @pack.weapon.nil? then
			touchable_zombie = @map.tiles_near(*@location, 1).flatten.map { |tile|
				tile.creature }.delete_if { |val| val.nil? }.select { |creature|
				creature.status == :zombie }.shuffle.first
			unless touchable_zombie.nil? then
				touchable_zombie.die
			end
		end
		
		# Move in the safest direction
		@brain.directions[@facing] = line_of_sight.flatten.inject(0) { |save, tile|
			save + ((tile.creature.nil?) ? 0 : (
				(tile.creature.status == :zombie) ? weight[:zombie] : weight[:human])) +
				((tile.include_weapon?) ? weight[:weapon] : 0)
		}

		move_in_best_direction
	end

	def move_in_best_direction
		ordered = @brain.directions.to_a.sort { |a, b| a.last <=> b.last }
		@facing = ordered.select { |i| i.last == ordered.first.last }.
			shuffle.first.first
		move_along_facing
	end

	def infect
		@brain.infection = rand(19) + 1
		@status = :infected
		@color = :yellow
	end

	def turn_to_zombie
		zed = Zombie.new(@map, @creature_list, @location, self)
		@creature_list.delete self
		@creature_list.push zed
		@map[*@location].creature = zed
		@creature_list.count[:humans] -= 1
		@creature_list.count[:zombies] += 1
	end
end

end
