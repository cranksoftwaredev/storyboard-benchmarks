-- Simple performance log print out wrapper
if(not gre.log_perf_stat) then
	gre.log_perf_stat = function(test, qualifier, result, description)
		print("PERF: " .. test .. ", " .. qualifier .. ", " .. tostring(result) .. ", " .. description);
	end
end