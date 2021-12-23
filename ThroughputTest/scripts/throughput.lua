-- Utility functions for the performance metrics

-- Inline mapping of the time function in case it is missing
if(not gre.mstime) then
	print("WARN: Missing mstime, simulating with os.clock() * 1000")
	gre.mstime = function() 
		return os.clock() * 1000
	end
end

-- Simple performance log print out wrapper
if(not gre.log_perf_stat) then
	gre.log_perf_stat = function(test, qualifier, result, description)
		print("PERF: " .. test .. ", " .. qualifier .. ", " .. tostring(result) .. ", " .. description);
	end
end


-- We don't use the 'gre.touch()' call because it has an internal delay
function send_touch(x, y)
  local fmt = "4u1 button 4u1 timestamp 2u1 subtype 2s1 x 2s1 y 2s1 z 2s1 id 2s1 spare"
  local data = { 
    button = 0; timestamp = 0, subtype = 0; x = 0, y = 0, z = 0, id = 0, spare = 0 
  }
  data.x = x
  data.y = y
  gre.send_event_data("gre.press", fmt, data)
  gre.send_event_data("gre.release", fmt, data)  
end 