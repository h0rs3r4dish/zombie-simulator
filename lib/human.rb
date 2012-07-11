require 'lib/creature'
require 'lib/patch/hash'

module ZedSim

class Human < Creature
	def initialize(*args)
		super *args
		@brain = Hash.new.to_struct
		@brain.directions = { :north => 0, :east => 0, :south => 0, :west => 0,
			:northeast => 0, :southeast => 0, :southwest => 0, :northwest => 0 }
		@brain.personality = [:stupid, :smart].shuffle.first
	end

	def tick
		if @status == :infected then
			@brain.infection -= 1
			if @brain.infection == 0
				turn_to_zombie
				return
			end
		end
		
		creatures_visible = line_of_sight.flatten.map { |tile| tile.creature }.
			delete_if { |creature| creature.nil? }
		@brain.directions[@facing] = creatures_visible.inject(0) { |save, creature|
			save + if creature.status == :zombie then
			   -1
			elsif @brain.personality == :smart
				1
			else
				0
			end
		}
		ordered = @brain.directions.to_a.sort { |a, b| a.last <=> b.last }
		@facing = ordered.select { |i| i.last == ordered.first.last }.
			shuffle.first.first
		move_along_facing
	end

	def infect
		@brain.infection = rand 10
		@status = :infected
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
