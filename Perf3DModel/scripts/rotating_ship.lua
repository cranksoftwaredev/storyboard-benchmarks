require "sbperftest"

local rotating_ship = {}

function rotating_ship.CBUpdate(mapargs, elapsedTime)
  local angle = (elapsedTime / 4.0) % 360.0; 
  gre.set_value("theta", angle)
end

sbperftest.RegisterPerfTest("rotating_ship_prime", rotating_ship)
sbperftest.RegisterPerfTest("rotating_ship_unlit", rotating_ship)
sbperftest.RegisterPerfTest("rotating_ship_gouraud", rotating_ship)
sbperftest.RegisterPerfTest("rotating_ship_blinnphong", rotating_ship)
