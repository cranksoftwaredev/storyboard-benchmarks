require "application"
require "sbperftest"

local circular__thin_stroke__big_open_arc = {}

local is_hidden = 1

function circular__thin_stroke__big_open_arc.CBUpdate(mapargs, elapsedTime)
  local data = {}
  
  is_hidden = 1 - is_hidden
  
  data["circular__thin_stroke__big_open_arc__layer.object1.grd_hidden"] = is_hidden

  gre.set_data(data)
end

sbperftest.RegisterPerfTest("circular__thin_stroke__big_open_arc", circular__thin_stroke__big_open_arc, application_test_duration())
