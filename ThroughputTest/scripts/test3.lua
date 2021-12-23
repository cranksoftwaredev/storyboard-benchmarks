
local test3_count
local test3_start
local test3_total

local test3_prefix = "T3L1.fill"
local test3_postfix = ".fill"
local fill_count = 20

function cb_test3_start() 
	test3_count = 0
	test3_total = 0
	test3_start= gre.mstime()
	gre.send_event("test3_event");
end

function cb_test3_event() 
	-- Measure the latency on this event
	local delta = gre.mstime() - test3_start
	test3_count = test3_count + 1
	test3_total = test3_total + delta

	local i, key, color1, color2
	if((test3_count % 2) == 0) then
		color1 = 0xff0000
		color2 = 0x0000ff	
	else
		color1 = 0x0000ff
		color2 = 0xff0000
	end		
	
	local dc = {}
	for i = 1,fill_count,1 do
		key = test3_prefix .. tostring(i) .. test3_postfix
		if((i % 2) == 0) then
			dc[key] = color1
		else
			dc[key] = color2
		end
	end
	
	-- Generate a data change and a new event
	test3_start= gre.mstime()
	if(test3_count < 1000) then
		gre.set_data(dc)
		gre.send_event("test3_event")
	else
		gre.send_event("test3_end")
	end
end

function cb_test3_end() 
	gre.log_perf_stat("Throughput", "MultiFillDataChangeEvent",  test3_total / test3_count, "ms/iteration")
	gre.send_event("next_test")
end