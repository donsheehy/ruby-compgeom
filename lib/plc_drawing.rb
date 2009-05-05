require 'ruby-processing'

class Processing::App
  def draw_plc(plc)
    stroke 0, 0.8
    plc.cells[1].each do |e|
      line e.head.x, e.head.y, e.tail.x, e.tail.y
    end

    fill 0.8, 0.7, 0.3, 0.5
    stroke 0, 0.2
    plc.cells[2].each do |t|
      triangle t.down(2)[0].x, t.down(2)[0].y, t.down(2)[1].x, t.down(2)[1].y, t.down(2)[2].x, t.down(2)[2].y
    end
  end
end

