require 'rubygems'
require 'spec'
require 'predicates'
include Predicates

describe Predicates do
  it "should compute orientations of points" do
    p = [[0,0], [5,6], [2,10]]
    orient(p[0],p[1],p[2]).should == 1
    orient(p[0],p[2],p[1]).should == -1
    orient([1/5, 1/5], [1/3, 1/3],[1/7, 1/7]).should == 0
  end
end