require 'rubygems'
require 'ruby-processing'

require 'simplicial_complex'
require 'piecewise_linear_complex'
require 'plc_drawing'

def test_grid(k)
  sc = SimplicialComplex.new(2)
  p, e = {}, {}
  # add the vertices
  for i in 0..k do
    for j in 0..k do
      p[[i,j]] = sc.add [i*20,j*20]
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

def random_tet
  width,height = 800, 600
  plc = PiecewiseLinearComplex.new(2)
  a = plc.add [rand(width), rand(height)]
  b = plc.add [rand(width), rand(height)]
  c = plc.add [rand(width), rand(height)]
  d = plc.add [rand(width), rand(height)]

  e1 = plc.add [a,b]
  e2 = plc.add [b,c]
  e3 = plc.add [c,a]
  e4 = plc.add [a,d]
  e5 = plc.add [b,d]
  e6 = plc.add [c,d]

  t1 = plc.add [e1,e2,e3]
 # t1 = plc.add [e3,e4,e6]
  plc
end

size 800, 600
color_mode RGB, 1.0
smooth

background 1.0

draw_plc(test_grid(30))
#10.times do draw_plc(random_tet) end
