require 'lib/creature'

module ZedSim

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
		@creature_list.count[:humans] -= 1
		@creature_list.count[:zombies] += 1
	end
end

end
