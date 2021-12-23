
local test6_count
local test6_start
local test6_total

local touchPointIndex = 0
local touchPoints = {}

function cb_test6_start() 
	test6_count = 0
	test6_total = 0
	
	touchPoints[1] = gre.get_control_attrs("T6L1.Touch1","x", "y")
	touchPoints[2] = gre.get_control_attrs("T6L1.Touch2","x", "y")
	
	test6_start= gre.mstime()
	gre.send_event("test_event");
end


function cb_test6_event() 
	-- Measure the latency on this event
	local delta = gre.mstime() - test6_start
	test6_count = test6_count + 1
	test6_total = test6_total + delta

  -- Bounce the touch back and forth
  local touchPoint = touchPoints[touchPointIndex + 1]
  touchPointIndex = (touchPointIndex + 1) % #touchPoints

	-- Generate a data change and a new event
	test6_start= gre.mstime()
	if(test6_count < 1000) then
	  send_touch(touchPoint.x, touchPoint.y)
		gre.send_event("test_event")
	else
		gre.send_event("test_end")
	end
end

function cb_test6_end() 
	gre.log_perf_stat("Throughput", "PressReleaseEvent",  test6_total / test6_count, "ms/iteration")
	gre.send_event("next_test")
end
