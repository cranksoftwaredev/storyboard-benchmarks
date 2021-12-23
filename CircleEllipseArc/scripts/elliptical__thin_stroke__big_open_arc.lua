require "application"
require "sbperftest"

local elliptical__thin_stroke__big_open_arc = {}

local is_hidden = 1

function elliptical__thin_stroke__big_open_arc.CBUpdate(mapargs, elapsedTime)
  local data = {}
  
  is_hidden = 1 - is_hidden
  
  data["elliptical__thin_stroke__big_open_arc__layer.object1.grd_hidden"] = is_hidden

  gre.set_data(data)
end

sbperftest.RegisterPerfTest("elliptical__thin_stroke__big_open_arc", elliptical__thin_stroke__big_open_arc, application_test_duration())
