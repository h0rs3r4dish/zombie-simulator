require 'lib/console/single-buffer'
require 'lib/map'
require 'lib/human'
require 'lib/zombie'

module ZedSim

class Game
	def initialize
		@console = Console.new
		@map = Map.new *CONFIG[:map]

		@creatures = Array.new
		@creatures.instance_variable_set :@count, { :zombies => 0, :humans => 0 }
		def @creatures.count; @count; end

		@creatures.count[:humans] = rand(CONFIG[:starting_humans].last) +
			CONFIG[:starting_humans].first
		@creatures.count[:humans].times { 
			loc = [rand(80), rand(24)]
			@creatures << Human.new(@map, @creatures, loc)
			@map[*loc].creature = @creatures.last
		}

		@creatures.count[:zombies] = rand(CONFIG[:starting_zombies].last) +
			CONFIG[:starting_zombies].first
		@creatures.count[:zombies].times { 
			loc = [rand(80), rand(24)]
			@creatures << Zombie.new(@map, @creatures, loc)
			@map[*loc].creature = @creatures.last
		}

		game_loop
	end

	def game_loop
		time_keeper = TimeKeeper.new(0.2)
		loop do
			@creatures.each { |creature| creature.tick }

			@console.on_key :timeout => time_keeper.mark do |key|
				exit if key == 'q'
				@console.getc if key == 'p'
			end

			game_end if @creatures.count.values.include? 0

			if CONFIG[:color] then
				@map.each { |row| row.each { |tile|
					@console.color tile.color; @console[tile]
				} }
			else
				@map.each { |row| @console[row.to_s] }
			end
			@console.draw
		end
	end
	def game_end
		victors = @creatures.count.to_a.select { |a| a.last != 0 }.flatten.
			first.to_s.capitalize
		(11..13).each { |y|
			@console.text 33,y, " " * 16
		}
		@console.text 35,12, "#{victors} win!"
		@console.draw
		@console.on_key :blocking => true do
			exit
		end
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
