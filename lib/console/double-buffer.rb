module ZedSim


class Console 
	
	def initialize(width=80,height=24)
		system "stty raw -echo"
		at_exit { system "stty -raw echo" }

		@buffer = Array.new(height).map { " " * width }
		@buffer.instance_variable_set :@width, width
		@buffer.instance_variable_set :@height, height
		class << @buffer; attr_reader :height, :width; end

		@changed = true
		@last_color = :white
		@cursor = Struct.new(:x,:y).new(0,0)
	end

	def draw(*args)
		return unless @changed
		@changed = false
		print "\033[0;0H"
		@buffer.each { |line| print line }
		print "\033[#{@cursor.y};#{@cursor.x}H" unless args.include? :without_cursor
	end

	def cursor_up(n=1); @cursor.y -= n; end
	def cursor_down(n=1); @cursor.y += n; end
	def cursor_left(n=1); @cursor.x -= n; end
	def cursor_right(n=1); @cursor.x += n; end
	def cursor_to(x,y); @cursor.x = x; @cursor.y = y; end

	def text(x,y,str)
		@changed = true
		str = str[0..(@buffer.width - x - 1)] if str.length + x >= @buffer.width
		@buffer[y][x..(x + str.length - 1)] = str
		if (@cursor.x += str.length) >= @buffer.width then
			@cursor.y = y + 1
			@cursor.y = 0 if @cursor.y >= @buffer.height 
			@cursor.x = 0
		end
	end
	def [](str)
		text @cursor.x, @cursor.y, str
	end

	def color(new_color)
		return if new_color == @last_color
		@last_color = new_color
	end

	def getc
		STDIN.getc
	end
	def on_key(args, &block)
		if args.key? :blocking then
			block.call(STDIN.getc)
		else
			timeout = (args.key? :timeout) ? args[:timeout] : nil
			input_source = select([STDIN],nil,nil,timeout)
			return if input_source.nil?
			block.call(input_source.flatten.first.getc)
		end
	end

end

end
