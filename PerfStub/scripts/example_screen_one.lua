-- example_screen_one.lua

require "sbperftest"

local example_screen_one = {}

function example_screen_one.CBUpdate(mapargs, elapsedTime)
  local posX = math.sin(elapsedTime / 400.0) * 200.0 + 336.0
  gre.set_value("example_screen_layer.square_object.grd_x", posX)
end

sbperftest.RegisterPerfTest("example_screen_one", example_screen_one)
