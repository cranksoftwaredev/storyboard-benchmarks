require "sbperftest"

local dual_gauges = {}

function dual_gauges.CBUpdate(mapargs, elapsedTime)
  local data = {}
  local angle = (elapsedTime / 4.0) % 360.0; 

  data["dual_gauges_layer.gauges.MPHNeedleControl_RY"] = angle
  data["dual_gauges_layer.gauges.RPMNeedleControl_RY"] = -angle
 
  gre.set_data(data)
end

sbperftest.RegisterPerfTest("dual_gauges_prime", dual_gauges)
sbperftest.RegisterPerfTest("dual_gauges_unlit", dual_gauges)
sbperftest.RegisterPerfTest("dual_gauges_gouraud", dual_gauges)
sbperftest.RegisterPerfTest("dual_gauges_blinnphong", dual_gauges)
