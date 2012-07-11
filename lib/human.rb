require 'lib/creature'
require 'lib/patch/hash'

module ZedSim

class Human < Creature
	def initialize(*args)
		super *args
		@logic = Hash.new.to_struct
		@logic.zombie_positions = { :north => 0, :east => 0, :south => 0, :west => 0,
			:northeast => 0, :southeast => 0, :southwest => 0, :northwest => 0 }
	end

	def tick
		if @status == :infected then
			turn_to_zombie
			return
		end
		
		zombies_at_facing = line_of_sight.flatten.map { |tile| tile.creature }.
			delete_if { |creature| creature.nil? }.select { |creature|
			creature.status == :zombie }.count
		@logic.zombie_positions[@facing] = zombies_at_facing
		ordered = @logic.zombie_positions.to_a.sort { |a, b| a.last <=> b.last }.
			reverse
		@facing = ordered.select { |i| i.last == ordered.first.last }.
			shuffle.first.first
		move_along_facing
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
