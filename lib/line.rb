class Line
	# Pass coordinates as [x0,y0] => [x1,y1], not as two arrays
	def initialize(data)
		@init_data = data
		@from = data.keys.first.clone
		@to   = data.values.first.clone
		@steep = ((to.last - from.last).abs) > ((to.first - from.first).abs)
		if @steep then
			@from.reverse!
			@to.reverse!
		end
#		if @from.first > @from.last then
#			@from[0],@to[0] = @to[0],@from[0]
#			@from[1],@to[1] = @to[1],@from[1]
#		end
		@dx = @to.first - @from.first
		@dy = (@to.last - @from.last).abs
		@x_step = ((@to.first > @from.first) ? 1 : -1)
		@y_step = ((@to.last > @from.last) ? 1 : -1)
		@error = @dx / 2
		@undo = { :from => nil, :error => nil }
	end
	def step
		@undo[:from] = @from.clone; @undo[:error] = @error
		@from[0] += @x_step
		@error -= @dy
		if @error < 0 then
			@from[1] += @y_step
			@error += @dx
		end
		return (@steep) ? @from.reverse : @from
	end
	def undo
		@from = @undo[:from]
		@error = @undo[:error]
	end
	def clear; self.initialize(@init_data); end

	def from; @init_data.keys.first; end
	def to; @init_data.values.first; end
end
