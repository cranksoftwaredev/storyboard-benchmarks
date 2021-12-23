-- example_screen_two.lua

require "sbperftest"

local example_screen_two = {}

function example_screen_two.CBUpdate(mapargs, elapsedTime)
  local posY = math.cos(elapsedTime / 100.0) * 80.0 + 176.0 
  gre.set_value("example_screen_layer.square_object.grd_y", posY)
end

sbperftest.RegisterPerfTest("example_screen_two", example_screen_two)
