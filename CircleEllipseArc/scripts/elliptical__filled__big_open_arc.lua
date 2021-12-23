require "application"
require "sbperftest"

local elliptical__filled__big_open_arc = {}

local is_hidden = 1

function elliptical__filled__big_open_arc.CBUpdate(mapargs, elapsedTime)
  local data = {}
  
  is_hidden = 1 - is_hidden
  
  data["elliptical__filled__big_open_arc__layer.object1.grd_hidden"] = is_hidden

  gre.set_data(data)
end

sbperftest.RegisterPerfTest("elliptical__filled__big_open_arc", elliptical__filled__big_open_arc, application_test_duration())
