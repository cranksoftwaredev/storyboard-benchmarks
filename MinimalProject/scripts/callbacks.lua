
local init_time
local screen_time

function cb_init(mapargs) 
  init_time = gre.mstime(true)
end

function cb_screenshow(mapargs)
  screen_time = gre.mstime(true)
  
  gre.log_perf_stat("MinimalProject", "InitEvent", tostring(init_time), "ms");
  
  gre.log_perf_stat("MinimalProject", "ScreenShow", tostring(screen_time), "ms");
  
  gre.send_event("gre.quit");
end
