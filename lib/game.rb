require 'lib/patch/helpers'
require 'lib/console/single-buffer'
require 'lib/map/map'
require 'lib/human'
require 'lib/zombie'
require 'lib/items'
require 'lib/extra/inspector'

module ZedSim

class Game
	def initialize
		@console = Console.new
		@map = Map.new *CONFIG[:map]

		@creatures = Array.new
		@creatures.instance_variable_set :@count, { :zombies => 0, :humans => 0 }
		def @creatures.count; @count; end

		@creatures.count[:humans] = rand_range CONFIG[:starting_humans]
		@creatures.count[:humans].times { 
			loc = random_coordinates :for => :creature
			@creatures << Human.new(@map, @creatures, loc)
		}

		@creatures.count[:zombies] = rand_range CONFIG[:starting_zombies]
		@creatures.count[:zombies].times { 
			loc = random_coordinates :for => :creature
			@creatures << Zombie.new(@map, @creatures, loc)
		}

		rand_range(CONFIG[:starting_weapons]).times {
			item = Item.new_random_weapon
			coords = random_coordinates(:for => :item)
			@map[*coords].items << Item.new_random_weapon
			@map[*coords].items << Item.new_random_ammo if item.range > 1
		}

		game_loop
	end

	def game_loop
		time_keeper = TimeKeeper.new(0.2)
		loop do
			log "-- TICK --"
			@creatures.each { |creature| creature.tick }

			draw_map

			@console.on_key :timeout => time_keeper.mark do |key|
				exit if key == CONFIG[:keys][:quit]
				@console.getc if key == CONFIG[:keys][:pause]
				inspector if key == CONFIG[:keys][:inspect]
			end

			game_end if @creatures.count.values.include? 0
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

	def draw_map
		@console.cursor_to 0,0
		if CONFIG[:color] then
			@map.each { |row| row.each { |tile|
				@console.color tile.color; @console[tile]
			} }
		else
			@map.each { |row| @console[row.to_s] }
		end
		@console.draw
	end

	def random_coordinates(h)
		coords = nil
		begin
			coords = [ rand(CONFIG[:map].first), rand(CONFIG[:map].last) ]
		end while (h[:for] == :creature and not @map[*coords].creature.nil?) or
			(h[:for] == :item and not @map[*coords].items.empty?)
		return coords
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
