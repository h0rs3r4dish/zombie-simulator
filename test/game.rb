require 'lib/game'

describe "ZedSim::Game" do
	it "should respond to a mock screen" do
		console = mock.as_null_object
		game = ZedSim::Game.new({}, console)
	end
end
