
g_buf = ''

function get_perf_data(mapargs)
		
	data = gre.get_data("action_type", "grd.transition.frames", "grd.transition.duration")
	local time = data["grd.transition.duration"]
	local frames = data["grd.transition.frames"]
	local fps = data["grd.transition.frames"] / (time/1000)
	local result = string.format("%0.2f",fps)
--	gre.log_perf_stat("Transition", data["action_type"], result, "fps")
	
	g_buf = g_buf.."Transition:  "..data["action_type"].." "..result.." fps\n" 
	
	text_update()
			
end

function text_update(mapargs)

	local txt_update = {}
	txt_update["results"] = g_buf
	gre.set_data(txt_update)  

end

function get_perf_data_animation(mapargs)
	
	local data = {}
	local result = 0	
	data = gre.get_data("grd.animation.name", "grd.animation.frames", "grd.animation.duration")
	local time = data["grd.animation.duration"]
	local frames = data["grd.animation.frames"]
	local fps = data["grd.animation.frames"] / (time/1000)
	local result = string.format("%0.2f",fps)
	--gre.log_perf_stat("Animation", data["grd.animation.name"], result, "fps")
	
	g_buf = g_buf.."Animation:  "..data["grd.animation.name"].." ".. result.." fps\n" 
	
	text_update()
		
end

function log_results(mapargs)
		
	local fp = io.open("./test_results.info","w")
	fp:write(g_buff)
	fp:close()

end

function quit_app(maprags)

	gre.send_event("gre.quit")
	
end