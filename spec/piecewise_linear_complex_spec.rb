require File.dirname(__FILE__) + '/spec_helper'
require 'piecewise_linear_complex'

describe PiecewiseLinearComplex do
  before :each do
    @plc = PiecewiseLinearComplex.new(2)
  end

  it "should be a cell complex" do @plc.should be_kind_of(CellComplex) end

  it "should store coordinates for 0-faces" do
    p = Array.new(5) { |i| @plc.add([2* i, i * i]) }
    p[0].coords.should == [0, 0]
    p[1].coords.should == [2, 1]
    p[2].coords.should == [4, 4]
  end

  it "should not store coordinates for higher dimensional faces" do
    p = Array.new(3) { |i| @plc.add([2* i, i * i]) }
    e = Array.new(3) { |i| @plc.add([p[i],p[(i+1) % 3]])}
    t = @plc.add(e)
    e[1].should_not be_kind_of(Vertex)
    t.should_not be_kind_of(Vertex)
  end

  it "should check that boundaries are flat" 
  
end