require 'lib/line'

describe "Line" do
	it "should initialize with a Hash argument" do
		Line.new([0,0] => [1,1])
	end
	it "should allow its points to be accessed" do
		l = Line.new([0,0] => [1,1])
		l.from.should == [0,0]
		l.to.should == [1,1]
	end
	it "should step cleanly through a 45 degree line" do
		l = Line.new([0,0] => [2,2])
		l.step.should == [1,1]
		l.step.should == [2,2]
	end
	it "should step cleanly through other lines" do
		l = Line.new([0,0] => [1,2])
		l.from.should == [0,0]
		l.to.should == [1,2]
		step = l.step
		step.should == [0,1]
		l.step.should == [1,2]
	end
	it "should handle lines going northwest" do
		l = Line.new([2,2] => [0,0])
		l.to.should == [0,0]
		l.from.should == [2,2]
		l.step.should == [1,1]
		l.step.should == [0,0]
	end
end
