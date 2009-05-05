require File.dirname(__FILE__) + '/spec_helper'
require 'simplicial_complex'
require 'predicates'

include Predicates

describe Simplex do
  before :each do
    @sc = double_tetrahedron
    @t1 = @sc.cells[3][0]
    @t2 = @sc.cells[3][1]
  end  

  it "should be able to get a list of its vertices" do
    v = @t1.vertices
    v.should be_instance_of(Array)
    v.length.should == 4
  end

  it "should be able to tell if a point is inside" do
    @t1.contains?([5,5,5]).should be_true
    @t1.contains?([500,500,500]).should be_false
    @t2.contains?([80,80,80]).should be_true
    @t2.contains?([-5,-5,-6]).should be_false
  end
end

describe SimplicialComplex do

  describe "Types: " do
    before :each do
      @sc = simple_grid 4
    end
    
    it "should be a piecewise linear complex" do
      @sc.should be_kind_of(PiecewiseLinearComplex) 
    end

    it "should have 0-cells that are vertices" do 
      @sc.cells[0].first.should be_instance_of(Vertex) 
    end

    it "should have d-cells that are simplices" do 
      @sc.cells[@sc.dim].each { |v| v.should be_instance_of(Simplex) }
    end
  end

  describe "Predicates: " do
    it "should be able to detect if a facet is Delaunay" do
      
    end
  end

  describe "Point Location: " do
    it "should be able to identify the cell containing a point" do
      sc = tetrahedron [[0,0,0],[0,10,0],[10,0,0],[0,0,10]]
      s = sc.locate([2,2,2])
      s.class.should == Simplex
      s.should == sc.cells[3].first
      sc.locate([10,10,10]).should be_nil
    end

    it "should work on larger examples" do
      sc = simple_grid 4
      s = [[12,1],[13,3],[23,1]].map { |p| sc.locate p}
      s.each {|tet| tet.should be_instance_of(Simplex)}
    end

  end

  describe "Traversal: " do
    it "should be possible to find the vertex opposite a tuple" do
      sc = double_tetrahedron
      t = sc.tuple(sc.cells[2][3]) # get a handle on the separating face
      t[0].should == sc.cells[0][1] # sanity check
      t[3].should == sc.cells[3][0] # sanity check
      sc.opposite_vertex(t)[0].should == sc.cells[0][4]
    end
  end

  describe "Local Modification: " do
    describe "Star Splits" do
      it "should split a tetrahedron to a star" do
        sc = tetrahedron [[0,0,0],[0,12,0],[12,0,0],[0,0,12]]
        t = sc.cells[3].first
        v = sc.add [3,3,3]
        v.down.first.dim.should == -1

        # Split the tetrahedron.
        sc.add_star v, t
        sc.cells[3].length.should == 4
        
        # Split one of the new tetrahedra.
        v = sc.add [1,5,5]
        t = sc.cells[3][1]
        t.contains?(v).should be_true # sanity check.
        sc.add_star v, t
        sc.cells[3].length.should == 7
      end
      
      it "should be easy to build a simplex by adding stars" do
        dim = 6
        sc = SimplicialComplex.new(dim)
        v = Array.new(dim + 1) { |i| sc.add Array.new(dim) {|j| i == j ? 100 : 0}}
        for i in 0...dim do
          sc.add_star v[i+1], sc.cells[i].first
          sc.cells[i+1].first.should_not be_nil
        end
      end
    end
    
    describe "Bistellar Flips" do
      before :each do
        @sc = double_tetrahedron
      end
      
      it "should swap the full-dimensional faces" do
        @sc.cells[3].length.should == 2
        # Flip it 2 to 3        
        @sc.flip(@sc.cells[2][3])        
        @sc.cells[3].length.should == 3  
        # Flip it back to 2
        @sc.flip(@sc.cells[2][8])
        @sc.cells[3].length.should == 2
      end
      
      it "should should get rid of extra face of lower dimensions" do
        @sc = double_tetrahedron
        # Flip 2 to 3
        @sc.flip(@sc.cells[2][3])        
        @sc.cells[2].length.should == 9  
        @sc.cells[1].length.should == 10  
        # Flip it back to 2
        @sc.flip(@sc.cells[2][8])
        @sc.cells[2].length.should == 7  
        @sc.cells[1].length.should == 9  
      end
    end
  end

end

def tetrahedron(points)
  sc = SimplicialComplex.new(3)
  p = points.map { |coords| sc.add(coords) }
  e = [[0,1],[0,2],[0,3],[1,2],[1,3],[2,3]].map { |ends| sc.add [p[ends[0]], p[ends[1]]] }
  t = [[0,1,3],[0,2,4],[1,2,5],[3,4,5]].map { |edges| sc.add [e[edges[0]], e[edges[1]], e[edges[2]]] }
  f =  sc.add t
  sc
end

def double_tetrahedron
  complex = SimplicialComplex.new(3)
  pts = [[0,0,0],[0,0,100],[0,100,0],[100,0,0],[100,100,100]]
  p = pts.map { |pt| complex.add pt }
  edges = [[0,1], [0,2], [0,3],
                [1,2], [2,3], [3,1], 
                [1,4], [4,2], [4,3]]
  faces = [[0,1,3], [0,2,5], [1,2,4],
           [3,4,5],
           [6,7,3], [7,8,4], [8,6,5]]
  tets = [[0,1,2,3], [3,4,5,6]]
  
  e = edges.map { |edge| complex.add [ p[edge[0]], p[edge[1]] ] }
  f = faces.map { |tri| complex.add [ e[tri[0]],e[tri[1]], e[tri[2]] ] }
  t = tets.map { |tet| complex.add [ f[tet[0]], f[tet[1]], f[tet[2]], f[tet[3]] ] } 
  complex
end

def simple_grid(k)
  sc = SimplicialComplex.new(2)
  p, e = {}, {}
  # add the vertices
  for i in 0..k do
    for j in 0..k do
      p[[i,j]] = sc.add [i*10,j*10]
    end
  end  
  #add the edges
  for i in 0...k do
    e[[i,k,0]] = sc.add [p[[i,k]], p[[i+1,k]]]
    e[[k,i,1]] = sc.add [p[[k,i]], p[[k,i+1]]]
  end
  for i in 0...k do
    for j in 0...k do
      e[[i,j,0]] = sc.add [p[[i,j]], p[[i+1,j]]]
      e[[i,j,1]] = sc.add [p[[i,j]], p[[i,j+1]]]
      e[[i,j,2]] = sc.add [p[[i,j]], p[[i+1,j+1]]]
    end
  end
  # add the triangles
  for i in 0...k do
    for j in 0...k do
      sc.add [e[[i,j,0]], e[[i,j,2]], e[[i+1,j,1]]]
      sc.add [e[[i,j,1]], e[[i,j,2]], e[[i,j+1,0]]]
    end
  end
  sc
end
