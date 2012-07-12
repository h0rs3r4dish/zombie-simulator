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
		@brain.priorities.push Objective.new(:find_weapon) if @brain.personality.
			include? :aggressive
		
		@brain.objective = nil

		@facing = @brain.directions.keys.shuffle.first
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

		@brain.objective = @brain.priorities.pop if @brain.objective.nil?

		unless @pack.weapon.nil? then
			touchable_zombie = @map.tiles_near(*@location, 1).flatten.map { |tile|
				tile.creature }.delete_if { |val| val.nil? }.select { |creature|
				creature.status == :zombie }.shuffle.first
			unless touchable_zombie.nil? then
				touchable_zombie.die if rand(100) < @pack.weapon.accuracy
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
				shelve_objective
			end
		when :find_weapon
			nearest_weapon = line_of_sight.flatten.select { |tile| 
				tile.include_weapon? }.sort { |tile_a, tile_b|
				distance_from(tile_a) <=> distance_from(tile_b) }.first
			if nearest_weapon.nil? then
				move_best_direction
			else
				if distance_from(nearest_weapon) < 2 then
					weapon = @map[*nearest_weapon.location].items.pop_weapon
					@pack.weapon = weapon
				else
					shelve_objective Objective.new(:goto, nearest_weapon.location)
					move_toward *@brain.objective.location
				end
			end
		when :goto
			if @location != location then
				move_toward *@brain.objective.location
			else
				@brain.objective = @brain.priorities.pop
			end
		end
	end

	def shelve_objective(replace_with=nil)
		current_objective = @brain.objective
		@brain.objective = if replace_with.nil? then
			@brain.priorities.pop
		else
			replace_with
		end
		@brain.priorities.push current_objective
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

	def infect
		@brain.infection = rand(19) + 1
		@status = :infected
		@color = :bright_yellow
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
