require 'cell_complex'

class Vertex < Cell
  attr_accessor :coords
  
  def initialize(complex)
    super(0, complex)
  end
  
  def x
    coords[0]
  end
  
  def y
    coords[1]
  end
  
  def [](k)
    coords[k]
  end
end

class Cell  
  def head
    self.down[0]
  end
  
  def tail
    self.down[1]
  end
end

class PiecewiseLinearComplex < CellComplex

  def new_cell(dim)
    dim == 0 ? Vertex.new(self) : super(dim)
  end
  
  def add(bdy_or_coords = [])
    
    boundary = bdy_or_coords.first.kind_of?(Fixnum) ? [] : bdy_or_coords
    cell = super(boundary)
    cell.coords = bdy_or_coords.clone if boundary.empty?
    cell
  end
  
end
