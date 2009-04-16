module Predicates
  require 'mathn'
  require 'matrix'

  def orient(*points)
    m = Matrix.rows(points.map {|p| p.clone << 1} )
    m.determinant <=> 0
  end
end