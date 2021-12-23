
local test2_count
local test2_start
local test2_total
local test2_key = "T2L1.t2fill.fill"

function cb_test2_start() 
	test2_count = 0
	test2_total = 0
	
	test2_start= gre.mstime()
	gre.send_event("test2_event");
end

function cb_test2_event() 
	-- Measure the latency on this event
	local delta = gre.mstime() - test2_start
	test2_count = test2_count + 1
	test2_total = test2_total + delta

	local dc = {}
	if((test2_count % 2) == 0) then
		dc[test2_key] = 0xff0000
	else
		dc[test2_key] = 0x0000ff
	end		
	
	-- Generate a data change and a new event
	test2_start= gre.mstime()
	if(test2_count < 1000) then
		gre.set_data(dc)
		gre.send_event("test2_event")
	else
		gre.send_event("test2_end")
	end
end

function cb_test2_end() 
	gre.log_perf_stat("Throughput", "FillDataChangeEvent",  test2_total / test2_count, "ms/iteration")
	gre.send_event("next_test")
end