require 'lib/console'
require 'lib/map'
require 'lib/creatures'

module ZedSim

class Game
	def initialize
		@console = Console.new
		@map = Map.new

		@creatures = Array.new

		(rand(12) + 3).times { 
			new_human( [rand(80),rand(24)] )
		}

		(rand(3) + 1).times {
			new_zombie( [rand(80),rand(24)] )
		}

		game_loop
	end

	def game_loop
		time_keeper = TimeKeeper.new(0.2)
		loop do
			@creatures.each { |creature| creature.tick }

			@console.on_key :timeout => time_keeper.mark do |key|
				exit if key == 'q'
			end

			@map.each { |row|
				@console[row]
			}
			@console.draw
		end
	end

	def new_human(loc)
		@creatures << Human.new(@map, @creatures, loc)
		@map[*loc].creature = @creatures.last
	end
	def new_zombie(loc)
		@creatures << Zombie.new(@map, @creatures, loc)
		@map[*loc].creature = @creatures.last
	end
end

class TimeKeeper
	def initialize(ideal_time)
		@time = Time.now.to_f
		@ideal = ideal_time
	end

	# Normalizes sleep_time towards @ideal, so that the time between regularly-
	# called marks approaches @ideal (in theory), without being higher or lower
	# than @ideal. Basically accounts for times when processing takes less than
	# or more than a negligable amount of time.
	def mark
		new_time = Time.now.to_f
		delta = new_time - @time
		sleep_time = @ideal - delta
		if sleep_time >= @ideal or sleep_time < 0 then
			@ideal
		else
			sleep_time
		end
	end
end

end
