require "application"
require "sbperftest"

local elliptical__thick_stroke__closed_arc = {}

local is_hidden = 1

function elliptical__thick_stroke__closed_arc.CBUpdate(mapargs, elapsedTime)
  local data = {}
  
  is_hidden = 1 - is_hidden
  
  data["elliptical__thick_stroke__closed_arc__layer.object1.grd_hidden"] = is_hidden

  gre.set_data(data)
end

sbperftest.RegisterPerfTest("elliptical__thick_stroke__closed_arc", elliptical__thick_stroke__closed_arc, application_test_duration())
