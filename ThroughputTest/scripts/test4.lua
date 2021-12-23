
local test4_count
local test4_start
local test4_total
local test4_key = "T4L1.t4image.image"

function cb_test4_start() 
	test4_count = 0
	test4_total = 0
	
	test4_start= gre.mstime()
	gre.send_event("test4_event");
end

function cb_test4_event() 
	-- Measure the latency on this event
	local delta = gre.mstime() - test4_start
	test4_count = test4_count + 1
	test4_total = test4_total + delta

	local dc = {}
	if((test4_count % 2) == 0) then
		dc[test4_key] = "images/image1.jpg"
	else
		dc[test4_key] = "images/image2.jpg"
	end		
	
	-- Generate a data change and a new event
	test4_start= gre.mstime()
	if(test4_count < 1000) then
		gre.set_data(dc)
		gre.send_event("test4_event")
	else
		gre.send_event("test4_end")
	end
end

function cb_test4_end() 
	gre.log_perf_stat("Throughput", "JPEGDataChangeEvent",  test4_total / test4_count, "ms/iteration")
	gre.send_event("next_test")
end