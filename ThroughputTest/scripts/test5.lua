
local test5_count
local test5_start
local test5_total

local test5_prefix = "T5L1.image"
local test5_postfix = ".image"
local fill_count = 20

function cb_test5_start() 
	test5_count = 0
	test5_total = 0
	
	test5_start= gre.mstime()
	gre.send_event("test5_event");
end

function cb_test5_event() 
	-- Measure the latency on this event
	local delta = gre.mstime() - test5_start
	test5_count = test5_count + 1
	test5_total = test5_total + delta

	local i, key, image1, image2
	if((test5_count % 2) == 0) then
		image1 = "images/image1.jpg"
		image2 = "images/image2.jpg"
	else
		image1 = "images/image2.jpg"
		image2 = "images/image1.jpg"
	end		
	
	local dc = {}
	for i = 1,fill_count,1 do
		key = test5_prefix .. tostring(i) .. test5_postfix
		if((i % 2) == 0) then
			dc[key] = image1
		else
			dc[key] = image2
		end
	end
	
	-- Generate a data change and a new event
	test5_start= gre.mstime()
	if(test5_count < 1000) then
		gre.set_data(dc)
		gre.send_event("test5_event")
	else
		gre.send_event("test5_end")
	end
end

function cb_test5_end() 
	gre.log_perf_stat("Throughput", "MultiJPEGDataChangeEvent",  test5_total / test5_count, "ms/iteration")
	gre.send_event("next_test")
end
