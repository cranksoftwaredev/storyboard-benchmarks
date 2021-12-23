require "sbperftest"

local moving_animated_annulus = {}

function moving_animated_annulus.CBUpdate(mapargs, elapsedTime)
  local data = {}

  local posX = math.sin(elapsedTime / 400.0) * 200.0 + 232.0
  local posY = math.cos(elapsedTime / 100.0) * 80.0 + 102.0 
  local arcWidth = math.sin(elapsedTime / 800.0) * 60.0 + 64.0  

  data.arc_width = arcWidth
  data["moving_annulus_layer.green_ann_1.grd_x"] = posX
  data["moving_annulus_layer.green_ann_1.grd_y"] = posY
  
  gre.set_data(data)
end

sbperftest.RegisterPerfTest("moving_animated_annulus", moving_animated_annulus)
