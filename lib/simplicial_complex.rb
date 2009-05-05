require 'piecewise_linear_complex'
require 'predicates'

# Represents a full dimenional simplex
class Simplex < Cell
  
  include Predicates
  def initialize(complex)
    super(complex.dim, complex)
  end

  def vertices
    down(@dim)
  end

  def contains?(point)
    points = vertices.map { |v| v.coords }
    p = points.clone
    orientation = orient(*p)
    new_point = point.instance_of?(Vertex) ? point.coords : point
    for i in 0..@dim do
      p[i] = new_point
      return false if (orient(*p) == -orientation)
      p[i] = points[i]
    end
    true
  end
  
end

class SimplicialComplex < PiecewiseLinearComplex
  
  def new_cell(dim)
    case dim
      when 0: Vertex.new(self)
      when @dim: Simplex.new(self)
      else super(dim)
    end
  end
  
  def locate(point)
    @cells[@dim].each {|t| return t if t.contains?(point)}
    nil
  end
  
  def add_star(vertex, simplex)
    h = { @empty_face => vertex }
    faces = Array.new(simplex.dim + 1) {|i| simplex.faces(i).clone }
    if simplex.dim == @dim
      dim = @dim - 1
      delete simplex
    else
      dim = simplex.dim   
    end
    for d in 0..dim do
      faces[d].each do |cell|
        boundary = cell.down.map { |f| h[f] } << cell
        h[cell] = add boundary 
      end
    end
  end
  
  def opposite_vertex(t)
    for i in 0..@dim do 
      return nil if t.nil?
      t = switch(@dim - i,t)
    end
    t
  end

  def next_facet(t)
    for i in 0...@dim do 
      return nil if t.nil?
      t = switch(@dim - 1 - i,t)
    end
    t
  end
  
  def flip(facet)
    all_vertices = facet.up.map { |s| s.vertices }.flatten.uniq
    q = [tuple(facet)]
    cells_to_flip_out = [q[0][@dim]]
    existing_faces = Array.new(@dim+1){ |i| {} }
    visited = {}
    
    # Find the cells to be flipped out
    while !q.empty? do
      t = q.pop
      visited[t[@dim-1]] = true
      t = opposite_vertex(t)
      if t and all_vertices.include?(t[0])
        cells_to_flip_out << t[@dim]
        (@dim + 1).times do
          t = next_facet(t)
          q.push t if !visited[t[@dim-1]]
        end
      end
    end
    
    # Build a list of the relevant faces
    cells_to_flip_out.each do |c|
      (0...@dim).each { |d| c.down(d).each { |e| existing_faces[@dim-1-d][e.down.sort] = e } }
    end

    # Delete the full-dimensional faces to be flipped out.
    cells_to_flip_out.each { |c| delete c }
    
    # build up a @dim+1 simplex recursively, only add faces that were previously not there.
    new_simplex = all_vertices[0]
    # Loop through the vertices
    for i in 0..@dim do
      # Add the star from vertex to simplex.
      vertex = all_vertices[i+1]
      simplex = new_simplex
      h = { @empty_face => vertex }
      # Keep it from trying to insert a @dim+1 simplex in the last iteration.
      dim = simplex.dim < @dim ? simplex.dim : @dim - 1
      for d in 0..dim do
        simplex.faces(d).each do |cell|
          boundary = cell.down.map { |f| h[f] } << cell
          new_simplex = existing_faces[d][boundary.sort] || add(boundary)
          h[cell] = new_simplex
        end
      end
    end
    
    # Remove the remaining unused faces.
    (0..@dim).each do |d|
      existing_faces[@dim - d].each { |k,v| delete v if @upper[v].empty? }
    end
        
  end
  
end