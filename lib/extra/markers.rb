module ZedSim

class AlertMarker < Creature
	SYMBOL = '!'
	def initialize(*args)
		super *args
		@life = 1
		@color = :bright_white
		@status = :temporary
	end
	def tick
		remove_self
	end
end


end
