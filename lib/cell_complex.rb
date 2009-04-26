# The basic Cell Complex data structure is a highly versatile way of storing
# an arbitrary complex.  It assumes that no two cells of any dimension share
# more than one face.  It permits one to walk around the parts of the complex
# that are boundaries of higher dimensional cells.  

# A basic *Cell* has a dimension and some complex that it belongs to.
class Cell
  include Comparable
  attr_reader :dim, :complex

  def initialize(dim = 0, complex = nil)
    raise "Cells must belong to a complex" if complex == nil
    @dim = dim
    @complex = complex
  end
  
  # Cells are ordered increasing by dimension.  Two cells with the same
  # dimension are arbitrarily and consistently ordered.
  def <=>(other)
    return 1 if other == nil
    @dim == other.dim ? self.object_id <=> other.object_id : @dim <=> other.dim
  end

  def up(offset = 1)
    @complex.up(self, offset)
  end

  def down(offset = 1)
    @complex.down(self, offset)
  end

end

# A *CellTuple* is an ordered list of cells, one for each dimension,
# representing a handle into a complex.  The tuple can also be viewed as a
# simplex of the barycentric subdivision of a complex.
class CellTuple
  include Enumerable
  attr_reader :dim, :tuple, :complex
  
  def initialize(complex = nil, *tuple)
    raise "tuple constructed with bad argument" unless tuple.is_a? Array
    @tuple = tuple.flatten
    raise "tuple list should be cells" unless @tuple[0].kind_of?(Cell)
    @complex = complex
    @dim = @tuple.length-1
    if complex and complex.dim != @dim
      raise "wrong number of cells (#{@dim + 1}) for a tuple in this complex (dim = #{complex.dim})"
    end
  end

  def each
    @tuple.each {yield}
  end

  def clone
    CellTuple.new(@complex, @tuple.clone)
  end

  def [](k)
    return @tuple[k]
  end

  def []=(k,cell)
    @tuple[k] = cell if k <= @dim
  end

  def to_s
    return "Tup: [ "+@tuple.join(", ")+" ]"
  end

end

# A *CellComplex* represents a collection of cells and their incidence
# relationships.  It implements a switch operator that can be used with cell 
# tuple objects.  
class CellComplex
  attr_reader :dim, :cells, :lower, :upper, :empty_face, :full_face

  # override this method if you are using a different object to store cells.
  def new_cell(dim)
    Cell.new(dim, self)    
  end

  def initialize(dim)
    #initialize the data structures
    @dim = dim
    @switch = Hash.new
    @cells = Array.new(dim+1) { [] }
    @lower = Hash.new { |h,k| h[k] = [] }
    @upper = Hash.new { |h,k| h[k] = [] }
    
    # Create special faces for the top and bottom of the face poset.
    @empty_face = new_cell(-1)
    @full_face = new_cell(dim + 1)
  end
  
  ## add
  ##
  ## Create a new cell with a given boundary and add it to the complex.
  def add(boundary = [])
    raise "Not a valid boundary" unless is_boundary?(boundary)
    
    # Determine the dimension of the new cell and its boundary
    boundary_dimension = boundary.empty? ? -1 : boundary[0].dim
    cell_dimension = boundary_dimension + 1

    # Set the boundary of 0-faces to be the empty face
    boundary = [@empty_face] if cell_dimension == 0

    # Create the new cell and add it to the complex
    cell = new_cell(cell_dimension)
    @lower[cell] = boundary.clone
    @upper[cell] = cell_dimension == @dim ? [@full_face] : []

    @cells[cell_dimension] << cell

    # add the new switch operations involving the new cell
    boundary.each do |facet|
      # add the new cell to the coboundary of its boundary
      @upper[facet] << cell

      if cell_dimension == @dim
        add_switches facet, @upper[facet], @full_face
      end
      
      @lower[facet].each do |face|
        facets = @upper[face] & boundary
        add_switches face, facets, cell
      end
    end

    # Return the newly created cell.
    return cell
  end

  def switch(k, tuple)
    raise "nil Tuple given to switch" if tuple == nil
    raise "non-Tuple given to switch" if !tuple.is_a? CellTuple
    raise "bad call to switch" if k<0 || k>tuple.dim
    raise "bad tuple given to switch" if !tuple.dim.is_a? Integer
    lower_face = k == 0 ? @empty_face : tuple[k-1]
    upper_face = k == @dim ? @full_face : tuple[k+1]
    other_cell = @switch[[lower_face, tuple[k], upper_face]]
    return nil if other_cell.nil? 
    new_tuple = tuple.clone
    new_tuple[k] = other_cell
    return new_tuple
  end

  ## delete
  ##
  ## delete the given cell from the complex.  All other cells
  ## that contain it in their boundary are also deleted.
  def delete cell
    # Do not delete the full face.
    return if cell == @full_face
    
    # Recursively delete cell's coboundary
    upper = @upper[cell].clone.each { |up_cell| delete up_cell }
    
    # Update the incidence and switch structures for the lower dimensions.
    @lower[cell].each do |facet|
      @switch[[facet, cell, @full_face]] = nil
      @lower[facet].each { |face| @switch[[face, facet, cell]] = nil }
      @upper[facet].delete(cell)
    end
    
    # Clear remaining data structures for cell.
    @cells[cell.dim].delete(cell)
  end

  ## down
  ##
  ## retrieve the cells lower than the parameter cell
  ## which are offset dimensions lower (offset >= 0)
  def down(cell, offset = 1)
    @lower[cell].map {|f| offset == 1 ? f : self.down(f, offset-1)}.flatten.uniq
  end

  ## up
  ##
  ## retrieve the cells higher than the parameter cell
  ## which are offset dimensions higher (offset >= 0)
  def up(cell, offset = 1)
    @upper[cell].map {|f| offset == 1 ? f : self.up(f, offset-1)}.flatten.uniq
  end

  ## tuple
  ##
  ## returns a tuple containing cells.
  def tuple(*cells)
    cells = [@cells[0][0]] if cells.empty?
    cells << @full_face
    cells.sort!
    path = []
    0.upto(cells.size - 2) do |i|
      p = rising_path(cells[i], cells[i+1])
      return nil if p.nil?
      path << p
      path.flatten!
    end
    tuple = (falling_path(cells[0]) << path[0..-2]).flatten
    CellTuple.new(self, tuple)
  end

private

  def is_boundary?(cells)
    h = Hash.new(0)
    cells.each do |f|
      @lower[f].each {|g| h[g] += 1}
    end
    h.detect { |_, v| v % 2 == 1}.nil?
  end

  def falling_path(s)
    return nil if s == nil
    return [s] if s.dim == 0
    @lower[s].each do |cell| 
      path = falling_path cell
      return path << s if path
    end
  end
  
  def rising_path(s, t)
    # We are done if s == t.
    return [] if s == t
    # Quit if the dimension is too high.
    return nil if t == nil || s.dim >= t.dim
    # Run depth-first-search up the poset.
    @upper[s].each do |cell| 
      path = rising_path cell, t
      return [cell] + path if path
    end
    # Return nil if the search turns up nothing.
    return nil
  end

  def add_switches(lower_face, switch_faces, upper_face)
    raise "diamond property violation" if switch_faces.length > 2
    if switch_faces.length == 2
      @switch[[lower_face, switch_faces[0], upper_face]] = switch_faces[1]
      @switch[[lower_face, switch_faces[1], upper_face]] = switch_faces[0]
    end
  end

end
