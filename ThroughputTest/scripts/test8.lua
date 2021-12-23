
local test8_count
local test8_start
local test8_total

local dummyCount = 31
local originalPositions = {}
local gotoOrigin = true

function cb_test8_start() 
	test8_count = 0
	test8_total = 0
	
	for i=0,dummyCount do
	 local control = string.format("T7L1.Dummy%d", i)
	 originalPositions[i] = gre.get_control_attrs(control,"x", "y")
  end

	test8_start= gre.mstime()
	gre.send_event("test_event");
end

function cb_test8_event() 
	-- Measure the latency on this event
	local delta = gre.mstime() - test8_start
	test8_count = test8_count + 1
	test8_total = test8_total + delta

  -- Move the controls back and forth (triggers redraw and data listeners)
  local data = {}
  for i=0,dummyCount do
    local control = string.format("T7L1.Dummy%d", i)
    if(gotoOrigin) then
      data[control .. ".x"] = 0
      data[control .. ".y"] = 0
    else 
      data[control .. ".x"] = originalPositions[i].x
      data[control .. ".y"] = originalPositions[i].y      
    end     
  end
  gotoOrigin = not gotoOrigin

	-- Generate a data change and a new event
	test8_start= gre.mstime()
	if(test8_count < 1000) then
    gre.set_data(data)
		gre.send_event("test_event")
	else
		gre.send_event("test_end")
	end
end

function cb_test8_end() 
	gre.log_perf_stat("Throughput", "MassControlMovement",  test8_total / test8_count, "ms/iteration")
	gre.send_event("next_test")
end
