require 'lib/creature'
require 'lib/patch/hash'

module ZedSim

class Human < Creature
	attr_reader :pack, :brain

	def initialize(*args)
		super *args

		@pack = {
			:weapon => nil,
			:equipment => []
		}.to_struct

		# Brain
		@brain = Hash.new.to_struct
		@brain.directions = Hash.new
		[ :north, :east, :south, :west, :northeast, :southeast, :southwest,
			:northwest ].each { |direction|
			@brain.directions[direction] = { :zombies => 0, :humans => 0,
				:weapons => 0, :ammo => 0 }
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
		@brain.ticks_without_zombie = 0

		@facing = @brain.directions.keys.shuffle.first

		# Condition
		@condition.stance = :standing
	end

	def tick
		if @condition.infected then
			log_self "infection level dropped to #{@brain.infection}"
			@brain.infection -= 1
			if @brain.infection == 0
				turn_to_zombie
				return
			end
		end

		bleed if @condition.bleeding and rand(5) < 3

		@brain.objective = @brain.priorities.pop if @brain.objective.nil?
		#log_self "obj: #{@brain.objective.type}, facing: #{@facing}"

		surrounding_tiles = @map.tiles_near(*@location, 1).flatten
		sight = line_of_sight.flatten

		unless @pack.weapon.nil? then
			touchable_zombie = surrounding_tiles.map { |tile|
				tile.creature }.delete_if { |val| val.nil? }.select { |creature|
				creature.status == :zombie }.shuffle.first
			unless touchable_zombie.nil? then
				@brain.ticks_without_zombie = -1
				attack touchable_zombie
			end
			if @pack.weapon.range > 1 then
				touchable_ammo = surrounding_tiles.select { |tile| tile.include_ammo? }.
					select { |tile| tile.items.select { |item| item.type == :ammo }.
					select { |item| item.size == @pack.weapon.ammo_type }.length > 0 }.
					shuffle.first
				pick_up_item(:ammo, touchable_ammo) unless touchable_ammo.nil?
			end
		else
			if @brain.priorities.include? :find_weapon then
				touchable_weapon = surrounding_tiles.select { |tile|
					tile.include_weapon? }.shuffle.first
				pick_up_item(:weapon, touchable_weapon) unless touchable_weapon.nil?
				@brain.priorities.delete :find_weapon
			end
		end

		case @brain.objective.type
		when :survive
			if @brain.ticks_without_zombie < 5
				move_best_direction
			else
				@facing = movable_directions.shuffle.first
				objective_shelve Objective.new(:find_group)
			end
		when :find_group
			nearest_human = sight.delete_if { |tile|
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
			else
				nearest_weapon = sight.select { |tile| tile.include_weapon? }.
					sort { |a, b| distance_from(a) <=> distance_from(b) }.first
				if nearest_weapon.nil? then
					move_best_direction :weapons => 2
				else
					if distance_from(nearest_weapon) < 2 then
						pick_up_item :weapon, nearest_weapon
						if @brain.personality.include?(:aggresive) and @brain.personality.
							include?(:stupid) then
							@brain.priorities << Objective.new(:hunt_zombies)
						end
						objective_next
					else
						objective_shelve Objective.new(:goto, nearest_weapon.location)
						move_toward *@brain.objective.location
					end
				end
			end
		when :find_ammo
			nearest_ammo = sight.select { |tile| tile.include_ammo? }.
				sort { |a, b| distance_from(a) <=> distance_from(b) }.first
			if nearest_ammo.nil? then
				move_best_direction :ammo => 2
			else
				if distance_from(nearest_ammo) < 2 then
					pick_up_item :ammo, nearest_ammo
					objective_next
				else
					objective_shelve Objective.new(:goto, nearest_ammo.location)
					move_toward *@brain.objective.location
				end
			end
		when :goto
			if @location != @brain.objective.location then
				move_toward *@brain.objective.location
			else
				objective_next
			end
		when :hunt_zombies
			if @pack.weapon.nil? then
				objective_shelve Objective.new(:find_weapon)
			else
				target_zombie = sight.map { |tile| tile.creature }.delete_if { |c|
					c.nil? }.select { |c| distance_from(c) <= @pack.weapon.range and 
					c.status == :zombie }.sort { |zed_a, zed_b|
					distance_from(zed_a) <=> distance_from(zed_b) }.first
				if target_zombie.nil? then
					move_best_direction :zombies => 1, :humans => (
						(@brain.personality.include? :smart) ? 1 : 0)
				else
					@brain.ticks_without_zombie = -1
					attack target_zombie
				end
			end

		end

		@brain.ticks_without_zombie +=  1
	end

	def objective_shelve(replace_with=nil)
		current_objective = @brain.objective
		@brain.objective = if replace_with.nil? then
			@brain.priorities.pop
		else
			replace_with
		end
		@brain.priorities.push current_objective
		log_self "has a new objective: #{@brain.objective.type}"
	end
	def objective_next
		@brain.objective = @brain.priorities.pop
		log_self "has a new objective: #{@brain.objective.type}"
	end

	def move_best_direction(changes={})
		lean = {
			:zombies => -((@condition.infected) ? 2 : 1),
			:humans  => (@brain.personality.include? :smart) ? 1 : 0,
			:weapons => 0,
			:ammo    => 0
		}
		changes.each_pair { |k,v| lean[k] = v }

		facing = @brain.directions[@facing] = { :zombies => 0, :humans => 0,
			:weapons => 0, :ammo => 0 }
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
			has << :ammo if tile.include_ammo?
			has
		}.each { |tile| tile.each { |factor| facing[factor] += 1 } }

		allowed_directions = movable_directions

		ordered = Array.new
		@brain.directions.delete_if { |direction, factors|
			not allowed_directions.include? direction }.each_pair { |direction, factors|
			ordered << [ direction, (factors.to_a.inject(0) { |total, factor|
				total + (factor.last * lean[factor.first]) }) ] }
		ordered = ordered.sort { |a, b| a.last <=> b.last }.select { |i|
			i.last == ordered.first.last }.shuffle.first
		@facing = ordered.first unless ordered.nil?
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
		if @pack.weapon.range > 1 then
			ammo = @pack.equipment.select { |item| item.type == :ammo }.
				select { |item| item.size == @pack.weapon.ammo }
			return if ammo.nil?
			return unless ammo.count > 0
			ammo.count -= 1
			alert_in_area @location, 5, :zombie, :attack
		end
		alert_in_area creature.location, 5, :alive, :attack
		if rand < @pack.weapon.accuracy then
			dmg = rand_range @pack.weapon.damage
			log_self "hit ##{creature.id.to_s 16} for #{dmg} damage"
			creature.damage dmg
		end
	end

	def pick_up_item(type, tile)
		case type
		when :weapon
			weapon = tile.items.pop_weapon
			@pack.weapon = weapon
			if weapon.range > 1 then
				@pack.equipment.select { |item| item.type == :ammo }.select { |item|
					item.size == weapon.ammo_type }.each { |item|
					weapon.ammo_count += item.count; @pack.equipment.delete item }
			end
			log_self "picked up weapon #{weapon.name}"
		when :ammo
			tile.items.each { |item|
				next unless item.type == :ammo
				tile.items.delete item
				log_self "picked up #{item.count}x #{item.name}"
				if @pack.weapon.range > 1 then
					if @pack.weapon.ammo_type == item.size then
						@pack.weapon.ammo_count += item.count
						next
					end
				end
				pack = @pack.equipment.select { |pack_item| item.type == :ammo }
					select { |pack_item| pack_item.size == item.size }
				if pack.nil? then
					@pack.equipment << item
				else
					pack.count += item.count
				end
			}
		end
	end

	def infect
		alert_in_area @location, 5, :alive, :defend
		@brain.infection = rand(19) + 1
		@condition.infected = true
		@color = :bright_yellow
		@condition.bleeding = true
		@creature_list.count[:zombies] += 1
	end
	def turn_to_zombie
		remove_self
		zed = Zombie.new(@map, @creature_list, @location, self)
		@creature_list.push zed
		log_self "has turned into zombie ##{@creature_list.last.id.to_s 16}"
	end

	def die
		@color = :white
		super
	end

	def inspect
		"#<Human @personality=#{@personality.inspect} @objective=#{
			@objective.inspect} @priorities=#{@priorities.inspect}"
	end
end

Objective = Struct.new(:type, :location)

end
