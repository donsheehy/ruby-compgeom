require 'rubygems'
require 'spec'
require 'cell_complex'

describe Cell do
  before :each do
    @complex = CellComplex.new(3)
    @cell = Cell.new(2, @complex)
  end

  it do @cell.should be_kind_of(Comparable) end
  
  it "should have a dimension" do @cell.dim.should == 2 end
    
  it "should know what complex owns it" do @cell.complex.should == @complex end
  
  it "should expose its boundary (with offsets)" do
    p,e,f,t = double_tetrahedron
    e[0].down.should == [p[0], p[1]]
    t[0].down.should == [f[0], f[1], f[2], f[3]]
    f[1].down.should == [e[0], e[2], e[5]]
    f[0].down(2).should == [p[0], p[1], p[2]]
    empty_face = p[1].down()
    empty_face.size.should == 1
    empty_face.first.dim.should == -1    
    
  end
  
  it "should expose its coboundary (with offsets)" do    
    p,e,f,t = double_tetrahedron
    p[0].up.should == [e[0], e[1], e[2]]
    e[1].up.should == [f[0], f[2]]
    p[4].up(3).should == [t[1]]
    e[3].up(2).should == [t[0], t[1]]
    full_face = t[1].up
    full_face.size.should == 1
    full_face.first.dim.should == 4    
  end
  
end

describe CellTuple do
  before :each do
    @complex = CellComplex.new(3)
    @p, @e, @f, @t = double_tetrahedron
    @tuple = @complex.tuple
  end
  it "should have a dimension" do
    @tuple.dim.should == 3
    (0..3).each do |i| 
      @tuple[i].should be_kind_of(Cell)
    end
  end
  
  it "should know what complex owns it" do
    @tuple.complex.should == @complex
  end
end

describe CellComplex do
  before :each do
    @complex = CellComplex.new(3)
    @points = @complex.cells[0]
    @edges = @complex.cells[1]
    @faces = @complex.cells[2]
  end
  
  describe "basic properties" do
    it "should have a dimension" do @complex.dim.should == 3 end

    it "should be expose list of cells for each dimension" do
      @complex.cells[0].should_not be_nil
      @complex.cells[1].should_not be_nil    
    end    
  end

  describe "Creating, Adding, and Deleting" do
    it "should be possible to create one" do @complex.should_not be_nil end
  
    it "should allow the user to add vertices" do
      @points.size.should == 0
      p1 = @complex.add
      @points.size.should == 1
      p2 = @complex.add
      @points.size.should == 2
      @edges.size.should == 0    
      @faces.size.should == 0    
    end
  
    it "should allow the user to add edges" do
      p1 = @complex.add([])
      p2 = @complex.add([])
      e  = @complex.add([p1,p2])
      @edges.should == [e]    
    end
  
    it "should allow the user to add other faces" do
      p = Array.new(4) {@complex.add}
      e1 = @complex.add [p[0],p[1]]
      e2 = @complex.add [p[1],p[2]]
      e3 = @complex.add [p[2],p[3]]
      e4 = @complex.add [p[0],p[3]]
      f = @complex.add [e1,e2,e3,e4]
      @points.size.should == 4
      @edges.size.should == 4    
      @faces.size.should == 1    
    end    
  
    it "should allow the user to delete faces" do
      # Create 5 points.
      p = Array.new(5) {@complex.add}
      # Connect the points in a path.
      e = Array.new(4) {|i| @complex.add [p[i], p[i+1]]}
      # Delete the last edge.
      @complex.delete e[3]

      @edges.size.should == 3
    
      # Add an edge to create a quadrilateral.
      e[3] = @complex.add [p[3], p[0]]
      f = @complex.add e
      @faces.size.should == 1

      # Deleting a vertex deletes the adjacent edges.
      @complex.delete p[0]
      @faces.size.should == 0
      @edges.size.should == 2
    
      # Create a new face.
      e[3] = @complex.add [p[3], p[1]]
      @complex.add e[1..3]
    
      # Deleting the edge should delete the face.
      @complex.delete e[2]
      @edges.size.should == 2
      @faces.size.should == 0
    
    end
  end
  
  describe "Navigating the complex" do
    before :each do
      @p, @e, @f, @t = double_tetrahedron
    end
    
    describe "Boundary operations" do
      it "should expose the boundary of a cell" do
        @complex.down(@t[0]).should == [@f[0], @f[1], @f[2], @f[3]]
        @complex.down(@f[1]).should == [@e[0], @e[2], @e[5]]
        @complex.down(@e[3]).should == [@p[1], @p[2]]
        empty_face = @complex.down(@p[1])
        empty_face.size.should == 1
        empty_face.first.dim.should == -1    
      end
      
      it "should expose the co-boundary of a cell" do
        @complex.up(@p[1]).should == [@e[0], @e[3], @e[5], @e[6]]
        @complex.up(@e[1]).should == [@f[0], @f[2]]
        @complex.up(@f[4]).should == [@t[1]]
        full_face = @complex.up(@t[1])
        full_face.size.should == 1
        full_face.first.dim.should == 4
      end    
  
      it "should expose the boundary with an offset" do
        @complex.down(@t[0], 2).sort.should == [@e[0],@e[1],@e[2],@e[3],@e[4],@e[5]].sort
        @complex.down(@t[0], 3).sort.should == [@p[0],@p[1],@p[2],@p[3]].sort
        @complex.down(@f[6], 2).sort.should == [@p[1],@p[3],@p[4]].sort
      end
  
      it "should expose the co-boundary with an offset" do
        @complex.up(@p[4], 2).sort.should == [@f[4],@f[5],@f[6]].sort
        @complex.up(@p[4], 3).sort.should == [@t[1]].sort
        @complex.up(@e[4], 2).sort.should == [@t[0],@t[1]].sort
      end
    end
    
    describe "Getting a handle in the complex" do
      it "should expose an arbitrary tuple" do
        tuple = @complex.tuple
        tuple.should_not be_nil
        tuple.dim.should == 3
        tuple.should be_instance_of(CellTuple)
        [0..3].each {|i| tuple[i].should_not be_nil}
      end
      
      it "should allow the user to get a tuple containing given cells" do
        p,e,f,t = double_tetrahedron

        tuple = @complex.tuple(p[0], f[1])
        tuple[0].should == p[0]
        tuple[2].should == f[1]
        [0..3].each {|i| tuple[i].should_not be_nil}

        tuple = @complex.tuple(t[1], p[2], e[7])
        tuple[0].should == p[2]
        tuple[1].should == e[7]
        tuple[3].should == t[1]
    
        # Impossible tuples should return nil.
        @complex.tuple(p[0],p[1]).should be_nil
        tuple = @complex.tuple(p[0],t[1]).should be_nil
      end
    end
    
    describe "Switches" do
      it "should allow switches on a tuple" do
        tuple = @complex.tuple(@p[1], @e[3], @f[3], @t[0])
        tuple.should_not be_nil
        
        # Switch to an adjacent face.
        tuple = @complex.switch(2,tuple)
        tuple.should be_instance_of(CellTuple)
        tuple.tuple.should == [@p[1], @e[3], @f[0], @t[0]]
  
        # Switch back.
        tuple = @complex.switch(2,tuple)
        tuple.tuple.should == [@p[1], @e[3], @f[3], @t[0]]
  
        # Switch to an adjacent edge.
        tuple = @complex.switch(1,tuple)
        tuple.tuple.should == [@p[1], @e[5], @f[3], @t[0]]
  
        (@complex.upper[@complex.empty_face] & [@p[1], @p[3]]).should == [@p[1], @p[3]]
  
        # Switch to an adjacent vertex.
        tuple = @complex.switch(0,tuple)
        tuple.tuple.should == [@p[3], @e[5], @f[3], @t[0]]
  
        # Switch to the adjacent tetrahedron.
        tuple = @complex.switch(3, tuple)
        tuple.tuple.should == [@p[3], @e[5], @f[3], @t[1]]
  
        # Switch back.
        tuple = @complex.switch(3,tuple)
        tuple.tuple.should == [@p[3], @e[5], @f[3], @t[0]]
      end
      
      it "should return nil when a switch does not exist" do
        tuple = @complex.tuple(@p[0], @e[0], @f[0], @t[0])
        tuple.should_not be_nil
        
        @complex.switch(3, tuple).should be_nil
      end
      
      it "should return nil when tuple is not in the cell complex" do
        some_other_complex = CellComplex.new(3)
        cells = Array.new(4) {|i| Cell.new(some_other_complex, i)}
        tuple = CellTuple.new(some_other_complex, cells)
        tuple.should_not be_nil
        @complex.switch(1, tuple).should be_nil
      end
    end
  end
end

def double_tetrahedron
  p = Array.new(5) {@complex.add}
  e, f, t = [], [], []
  edge_pairs = [[0,1], [0,2], [0,3],
                [1,2], [2,3], [3,1], 
                [1,4], [4,2], [4,3]]
  faces = [[0,1,3], [0,2,5], [1,2,4],
           [3,4,5],
           [6,7,3], [7,8,4], [8,6,5]]
  tets = [[0,1,2,3], [3,4,5,6]]
  
  edge_pairs.each { |edge| e << (@complex.add [ p[edge[0]], p[edge[1]] ]) }
  faces.each { |tri| f << (@complex.add [ e[tri[0]],e[tri[1]], e[tri[2]] ]) }
  tets.each { |tet| t << (@complex.add [0,1,2,3].map { |i| f[tet[i]] }) } 

  return p, e, f, t
end