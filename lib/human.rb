require 'lib/creature'
require 'lib/patch/hash'

module ZedSim

class Human < Creature
	attr_reader :pack

	def initialize(*args)
		super *args

		@pack = {
			:weapon => nil,
			:equipment => []
		}.to_struct
		@brain = Hash.new.to_struct

		@brain.directions = Hash.new
		[ :north, :east, :south, :west, :northeast, :southeast, :southwest,
			:northwest ].each { |direction|
			@brain.directions[direction] = { :zombies => 0, :humans => 0,
				:weapons => 0 }
		}

		@brain.personality = [
			[:stupid, :smart].shuffle.first,
			[:aggressive, :cowardly].shuffle.first
		]

		@brain.priorities = [ Objective.new(:survive) ]
		@brain.priorities.push Objective.new(:find_group) if @brain.personality.
			include? :smart
		@brain.priorities.push Objective.new(:find_weapon)# if @brain.personality.
			#include? :aggressive
		
		@brain.objective = nil

		@facing = @brain.directions.keys.shuffle.first
		@bleeding = false
	end

	def tick
		if @status == :infected then
			log "##{@id} infection level #{@brain.infection}"
			@brain.infection -= 1
			if @brain.infection == 0
				turn_to_zombie
				return
			end
		end

		bleed if @bleeding and rand(5) < 3

		@brain.objective = @brain.priorities.pop if @brain.objective.nil?

		surrounding_tiles = @map.tiles_near(*@location, 1).flatten

		unless @pack.weapon.nil? then
			touchable_zombie = surrounding_tiles.map { |tile|
				tile.creature }.delete_if { |val| val.nil? }.select { |creature|
				creature.status == :zombie }.shuffle.first
			unless touchable_zombie.nil? then
				attack touchable_zombie
			end
		else
			if @brain.priorities.include? :find_weapon then
				touchable_weapon = surrounding_tiles.select { |tile|
					tile.include_weapon? }.shuffle.first
				pick_up_item(:weapon, touchable_weapon) unless touchable_weapon.nil?
			end
		end

		case @brain.objective.type
		when :survive
			move_best_direction
		when :find_group
			nearest_human = line_of_sight.flatten.delete_if { |tile|
				tile.creature.nil? }.select { |tile|
				tile.creature.status != :zombie }.sort { |a, b|
				distance_from(a) <=> distance_from(b) }.first
			if nearest_human.nil? then
				move_best_direction :humans => 2
			elsif distance_from(nearest_human) > 3 then
				move_best_direction :humans => 2
			else
				objective_next
			end
		when :find_weapon
			unless @pack.weapon.nil? then
				@brain.objective = Objective.new(:hunt_zombies) if @brain.personality.
					include? :aggressive
				return
			end
			nearest_weapon = line_of_sight.flatten.select { |tile| 
				tile.include_weapon? }.sort { |tile_a, tile_b|
				distance_from(tile_a) <=> distance_from(tile_b) }.first
			if nearest_weapon.nil? then
				move_best_direction :weapons => 2
			else
				if distance_from(nearest_weapon) < 2 then
					pick_up_item :weapon, nearest_weapon
					@brain.objective = Objective.new(:hunt_zombies) if @brain.
						personality.include?(:aggresive) and @brain.personality.
						include?(:stupid)
				else
					objective_shelve Objective.new(:goto, nearest_weapon.location)
					move_toward *@brain.objective.location
				end
			end
		when :goto
			if @location != location then
				move_toward *@brain.objective.location
			else
				objective_next
			end
		when :hunt_zombies
			if @pack.weapon.nil? then
				objective_shelve Objective.new(:find_weapon)
			else
				target_zombie = @map.tiles_near(*@location, @pack.weapon.range).flatten.
					map { |tile| tile.creature }.delete_if { |c| c.nil? }.select { |c|
					c.status == :zombie }.sort { |zed_a, zed_b|
					distance_from(zed_a) <=> distance_from(zed_b) }.first
				if target_zombie.nil? then
					move_best_direction :zombies => 1, :humans => (
						(@brain.personality.include? :smart) ? 1 : 0)
				else
					attack(target_zombie) unless target_zombie.nil?
				end
			end

		end
	end

	def objective_shelve(replace_with=nil)
		current_objective = @brain.objective
		@brain.objective = if replace_with.nil? then
			@brain.priorities.pop
		else
			replace_with
		end
		@brain.priorities.push current_objective
	end
	def objective_next
		@brain.objective = @brain.priorities.pop
	end

	def move_best_direction(changes={})
		lean = {
			:zombies => -1,
			:humans  => (@brain.personality.include? :smart) ? 1 : 0,
			:weapons => 0
		}
		changes.each_pair { |k,v| lean[k] = v }

		facing = @brain.directions[@facing] = { :zombies => 0, :humans => 0,
			:weapons => 0 }
		line_of_sight.flatten.map { |tile|
			has = Array.new
			unless tile.creature.nil? then
				if tile.creature.status == :zombie then
					has << :zombies
				else
					has << :humans
				end
			end
			has << :weapons if tile.include_weapon?
			has
		}.each { |tile| tile.each { |factor| facing[factor] += 1 } }

		banned_directions = Array.new
		if @location.first == 0 then
			banned_directions << :west
		elsif @location.first == @map.width - 1 then
			banned_directions << :east
		end
		if @location.last == 0 then
			banned_directions << :north
			banned_directions << :northwest if banned_directions.include? :west
			banned_directions << :northeast if banned_directions.include? :east
		elsif @location.last == @map.height - 1 then
			banned_directions << :south
			banned_directions << :southwest if banned_directions.include? :west
			banned_directions << :southeast if banned_directions.include? :east
		end

		ordered = Array.new
		@brain.directions.delete_if { |direction, factors|
			banned_directions.include? direction }.each_pair { |direction, factors|
			ordered << [ direction, (factors.to_a.inject(0) { |total, factor|
				total + (factor.last * lean[factor.first]) }) ] }
		@facing = ordered.sort { |a, b| a.last <=> b.last }.select { |i|
			i.last == ordered.first.last }.shuffle.first.first
		move_along_facing
	end

	def alert(loc, type=nil)
		case type
		when :attack
			return unless @brain.personality.include?(:aggressive) and not @pack.
				weapon.nil?
		when :defend
			return if @pack.weapon.nil?
		end
		objective_shelve Objective.new(:goto, loc)
	end
	def attack(creature)
		alert_in_area creature.location, 5, [:alive,:infected], :attack
		creature.attack(rand_range @pack.weapon.damage) if rand(100) < @pack
			.weapon.accuracy
	end

	def pick_up_item(type, tile)
		case type
		when :weapon
			weapon = tile.items.pop_weapon
			@pack.weapon = weapon
		end
	end

	def infect
		alert_in_area @location, 5, [:alive,:infected], :defend
		@brain.infection = rand(19) + 1
		@status = :infected
		@color = :bright_yellow
		@bleeding = true
	end
	def turn_to_zombie
		remove_self
		zed = Zombie.new(@map, @creature_list, @location, self)
		@creature_list.push zed
		@creature_list.count[:humans] -= 1
		@creature_list.count[:zombies] += 1
	end

	def inspect
		"#<Human @personality=#{@personality.inspect} @objective=#{
			@objective.inspect} @priorities=#{@priorities.inspect}"
	end
end

Objective = Struct.new(:type, :location)

end
