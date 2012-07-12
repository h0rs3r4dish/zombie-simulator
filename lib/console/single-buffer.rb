module ZedSim

class Console
	def initialize(width=80,height=24)
		system "stty raw -echo"
		at_exit { system "stty -raw echo" }
		@last_color = :default
		@width = width
		@height = height
	end

	def text(x,y,str)
		str = str[0..(@width - x - 1)] if str.length + x >= @width
		print "\033[#{y};#{x}H#{str}"
	end
	def [](str)
		print str
	end

	def draw; end

	def color(new_color)
		return if new_color == @last_color
		@last_color = new_color
		print "\033[#{
			(if new_color.to_s.include? 'bright_' then
				new_color = new_color.to_s.sub('bright_','').intern
				'1;'
			else '0' end) + (case new_color
			when :default
				'0;'
			when :white
				'37'
			when :red
				'31'
			when :green
				'32'
			when :blue
				'34'
			when :yellow
				'33'
			when :gray
				'30'
			end)
		}m"
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
