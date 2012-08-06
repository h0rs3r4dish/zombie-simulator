module ZedSim
class Game


	def inspector
		cursor = [1,1]
		bottom = @map.height
		fstring = "%-#{@map.width}s"
		while (key = @console.getc) != CONFIG[:keys][:quit]
			case key
			when CONFIG[:keys][:move_left]
				cursor[0] -= 1 unless cursor.first == 0
			when CONFIG[:keys][:move_down]
				cursor[1] += 1 unless cursor.last == @map.height
			when CONFIG[:keys][:move_up]
				cursor[1] -= 1 unless cursor.last == 0
			when CONFIG[:keys][:move_right]
				cursor[0] += 1 unless cursor.first == @map.width
			when '$'
				cursor[0] = @map.width
			when '^'
				cursor[0] = 0
			when 'G'
				cursor[1] = @map.height
			when 'g'
				str = ''
				@console.cursor_to 0, bottom
				print "Go to: "
				loop do
					key = @console.getc
					break if key == "\r"
					print key
					str += key
				end
				cursor = str.split(',').map { |d| d.to_i }
			when 'i'
				tile = @map[*cursor.map { |i| i - 1 }]
				unless tile.creature.nil? then
					if tile.creature.status != :zombie then
						person = tile.creature
						[
							"Personality: %s" % person.brain.personality.join(', '),
							"Objective: %s" % person.brain.objective.to_s,
							"Pack: %s %s" % [person.pack.weapon.to_s,
											 person.pack.equipment.join(', ')]
						].each_with_index { |line, i|
							@console.cursor_to 0,(i+1)
							print line
						}
						@console.getc
						@console.cursor_to 0,0
						draw_map
					end
				end
			end
			tile = @map[*cursor.map { |i| i - 1 }]
			str = ''
			if not tile.creature.nil? then
				creature = tile.creature
				str += (if creature.status == :zombie then
					"Zombie ##{creature.id.to_s 16}"
				else
					statuses = Array.new
					statuses << "infected" if creature.condition.infected
					statuses << "bleeding" if creature.condition.bleeding
					statuses << "armed" unless creature.pack.weapon.nil?
					"Human ##{creature.id.to_s 16}" + ( (statuses.length > 0) ?
						" (#{statuses.join(', ')})" : "" )
				end) + " on "
			elsif not tile.items.empty? then
				str += tile.items.map { |i| i.name }.join(', ') + " on "
			end
			str += (tile.base_color == :bright_gray) ? "ground" : "bloody ground"
			@console.text(0,bottom, fstring % str)
			@console.cursor_to *cursor
		end
		@console.cursor_to 0,0
	end

end
end
