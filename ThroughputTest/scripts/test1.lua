
local test1_count
local test1_start
local test1_total

function cb_test1_start() 
	test1_count = 0
	test1_total = 0
	
	test1_start= gre.mstime()
	gre.send_event("test1_event");
end

function cb_test1_event() 
	-- Measure the latency on this event
	local delta = gre.mstime() - test1_start
	test1_count = test1_count + 1
	test1_total = test1_total + delta
	
	-- Generate the next event
	test1_start= gre.mstime()
	if(test1_count < 1000) then
		gre.send_event("test1_event")
	else
		gre.send_event("test1_end")
	end
end

function cb_test1_end() 
	gre.log_perf_stat("Throughput", "LuaEvent",  test1_total / test1_count, "ms/iteration")
	gre.send_event("next_test")
end