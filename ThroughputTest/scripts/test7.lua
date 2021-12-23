
local test7_count
local test7_start
local test7_total

local touchPointIndex = 0
local touchPoints = {}

function cb_test7_start() 
	test7_count = 0
	test7_total = 0
	
	touchPoints[1] = gre.get_control_attrs("T7L1.Touch1","x", "y")
	touchPoints[2] = gre.get_control_attrs("T7L1.Touch2","x", "y")
	
	test7_start= gre.mstime()
	gre.send_event("test_event");
end

function cb_test7_event() 
	-- Measure the latency on this event
	local delta = gre.mstime() - test7_start
	test7_count = test7_count + 1
	test7_total = test7_total + delta

  -- Bounce the touch back and forth
  local touchPoint = touchPoints[touchPointIndex + 1]
  touchPointIndex = (touchPointIndex + 1) % #touchPoints

	-- Generate a data change and a new event
	test7_start= gre.mstime()
	if(test7_count < 1000) then
	  send_touch(touchPoint.x, touchPoint.y)
		gre.send_event("test_event")
	else
		gre.send_event("test_end")
	end
end

function cb_test7_end() 
	gre.log_perf_stat("Throughput", "PressReleaseEventStackedWithFocus",  test7_total / test7_count, "ms/iteration")
	gre.send_event("next_test")
end
