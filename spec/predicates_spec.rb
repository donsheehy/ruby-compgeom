$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib/"

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

  it "should also work in 3d" do
    p = [[0,0,1], [5,6,2], [2,10,3], [2,3,-19]]
    orient(p[0],p[1],p[2], p[3]).should == 1
    orient(p[0],p[2],p[1], p[3]).should == -1
    orient([1/5, 1/5,1], [1/3, 1/3,1],[1/7, 1/7,1], [0,0,0,0]).should == 0
  end

  it "should accept an array of points" do
    p = [[0,0,1], [5,6,2], [2,10,3], [2,3,-19]]
    orient(*p).should == 1
    temp = p[0]
    p[0] = p[1]
    p[1] = temp
  end

  it "should be consistent with point orders" do
    pts = [[0,0,0],[0,0,100],[0,100,0],[100,0,0]]
    p = pts.clone
    orientation = orient(*p)
    a = [5,5,5]
    for i in 0..3 do
      p[i] = a
      orient(*p).should == orientation
      p[i] = pts[i]
    end

    count = 0 
    a = [100,100,100]
    for i in 0..3 do
      p[i] = a
      count += 1 if orient(*p) == orientation
      p[i] = pts[i]
    end
    count.should == 3
  end

end