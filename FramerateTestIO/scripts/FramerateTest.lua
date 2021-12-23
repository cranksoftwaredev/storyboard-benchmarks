-- Options to help with performance testing
	local g_update_banner = 1      --scroll the banner
	local g_update_boxes = 1       -- move boxes in and out
	local g_update_stars = 1       -- zoom starts in an out
	local g_show_stars = 1         -- hide the star completely
	local g_wrap_text = 1          -- wrap text in box
	local g_scale_box_images = 1   -- scale the image in the background of the box
--

local verticalConstraint = 100;
local horizontalConstraint = 100;
local scale = 1;
local panorama1X = 0;
local panorama2X = 0;

local sampleFPS = 0;
local sampleDuration = 500; --frames are incremented on each render, sampleDuration says how many milliseconds to average that data over before displaying
local lastSampledTime = 0;
local sampleFrames = 0;

function calculateFramerate()
	sampleFrames = sampleFrames + 1
	local diff = getTimer() - lastSampledTime;
	
	if diff >= sampleDuration then
		local rawFPS = sampleFrames/(diff/1000)
		sampleFPS = math.floor(rawFPS*100)/100 --format as XX.XX
		sampleFrames = 0;
		lastSampledTime = getTimer();
	end
end


local startTime = gre.mstime()

function frametest_init(mapargs)
	local data = {}
	
	if g_wrap_text == 1 then
		data["box_layer.WordWrap"] = 1
	else
		data["box_layer.WordWrap"] = 0
	end
	
	if g_scale_box_images == 1 then
		data["box_layer.BoxScale"] = 1
	else
		data["box_layer.BoxScale"] = 0
	end	
	
	if g_show_stars == 1 then
		data["Screen1.star_layer.grd_hidden"] = 0
	else
		data["Screen1.star_layer.grd_hidden"] = 1
	end
	
	gre.set_data(data)
end

function getTimer()
	return  math.floor(gre.mstime() - startTime)
end
	
function cb_got_timer(mapargs)
	calculateFramerate()
	tweenValues()
	executeBindings()
end
	
function tweenValues()
	--calulate see-saw values
	stretchTime = getTimer() % 2000;
	oneSecMilli = math.max(getTimer() % 1000, 1);
	oneSecDuration = 0
	
	if stretchTime < 1000 then
		oneSecDuration = 0+(oneSecMilli/1000)
	else
		oneSecDuration = 1-(oneSecMilli/1000)
	end
	
	verticalConstraint = 100+(oneSecDuration*200)
	horizontalConstraint = 100+(oneSecDuration*350)
	scale = 1+(oneSecDuration*4);
	
	--calculate panorama
	panTime = getTimer() % 4000;
	twoSecMilli = math.max(getTimer() % 2000, 1)
	twoSecPos = math.ceil((twoSecMilli/2000)*1000)
	
	if panTime < 2000 then
		panorama1X = 0-twoSecPos
		panorama2X = 1000-twoSecPos
	else
		panorama1X = 1000-twoSecPos
		panorama2X = 0-twoSecPos
	end
end

function px(val)
	return val+50;
end

function padMore(val)
	return (val+5)
end

function padLess(val)
	return (val-10)
end

function executeBindings()
	local data = {}
	--document.getElementById("panImage1").style.left = panorama1X+"px"
	--document.getElementById("panImage2").style.left = panorama2X+"px";
	data["fps"] = tostring(sampleFPS)
	
	if g_update_banner == 1 then
		data["banner_layer.banner1.grd_x"] = panorama1X
		data["banner_layer.banner2.grd_x"] = panorama2X
	end

	middleHorizW = 1000-(horizontalConstraint*2)
    middleVertH = 700-(verticalConstraint*2)
    
	if g_update_boxes == 1 then
		data["box_layer.holder1.grd_x"] = 0
		data["box_layer.holder1.grd_y"] = 0
		data["box_layer.holder1.grd_width"] = horizontalConstraint
		data["box_layer.holder1.grd_height"] = verticalConstraint
	
		data["box_layer.holder2.grd_x"] = padMore(horizontalConstraint)
		data["box_layer.holder2.grd_y"] = 0
		data["box_layer.holder2.grd_width"] = padLess(middleHorizW)
		data["box_layer.holder2.grd_height"] = verticalConstraint
	
		data["box_layer.holder3.grd_x"] = 1000-horizontalConstraint
		data["box_layer.holder3.grd_y"] = 0
		data["box_layer.holder3.grd_width"] = horizontalConstraint
		data["box_layer.holder3.grd_height"] = verticalConstraint
	
		data["box_layer.holder4.grd_x"] = 0
		data["box_layer.holder4.grd_y"] = padMore(verticalConstraint)
		data["box_layer.holder4.grd_width"] = horizontalConstraint
		data["box_layer.holder4.grd_height"] = padLess(middleVertH)
	
		data["box_layer.holder5.grd_x"] = padMore(horizontalConstraint)
		data["box_layer.holder5.grd_y"] = padMore(verticalConstraint)
		data["box_layer.holder5.grd_width"] = padLess(middleHorizW)
		data["box_layer.holder5.grd_height"] = padLess(middleVertH)
	
		data["box_layer.holder6.grd_x"] = 1000-horizontalConstraint
		data["box_layer.holder6.grd_y"] = padMore(verticalConstraint)
		data["box_layer.holder6.grd_width"] = horizontalConstraint
		data["box_layer.holder6.grd_height"] = padLess(middleVertH)
	
		data["box_layer.holder7.grd_x"] = 0
		data["box_layer.holder7.grd_y"] = 700-verticalConstraint
		data["box_layer.holder7.grd_width"] = horizontalConstraint
		data["box_layer.holder7.grd_height"] = verticalConstraint
	
		data["box_layer.holder8.grd_x"] = padMore(horizontalConstraint)
		data["box_layer.holder8.grd_y"] = 700-verticalConstraint
		data["box_layer.holder8.grd_width"] = padLess(middleHorizW)
		data["box_layer.holder8.grd_height"] = verticalConstraint
	
		data["box_layer.holder9.grd_x"] = 1000-horizontalConstraint
		data["box_layer.holder9.grd_y"] = 700-verticalConstraint
		data["box_layer.holder9.grd_width"] = horizontalConstraint
		data["box_layer.holder9.grd_height"] = verticalConstraint
	end

	if g_update_stars == 1 then
		-- set stars
		starsize = 100*scale
	
		data["star_layer.star1.grd_x"] = 500-(starsize/2)
		data["star_layer.star1.grd_y"] = 250-(starsize/2)
		data["star_layer.star1.grd_width"] = starsize
		data["star_layer.star1.grd_height"] = starsize
	
		data["star_layer.star2.grd_x"] = 500-(starsize/2)
		data["star_layer.star2.grd_y"] = 450-(starsize/2)
		data["star_layer.star2.grd_width"] = starsize
		data["star_layer.star2.grd_height"] = starsize
				
		starsize = 600-starsize;
	
		data["star_layer.star3.grd_x"] = 400-(starsize/2)
		data["star_layer.star3.grd_y"] = 350-(starsize/2)
		data["star_layer.star3.grd_width"] = starsize
		data["star_layer.star3.grd_height"] = starsize
	
		data["star_layer.star4.grd_x"] = 600-(starsize/2)
		data["star_layer.star4.grd_y"] = 350-(starsize/2)
		data["star_layer.star4.grd_width"] = starsize
		data["star_layer.star4.grd_height"] = starsize	
	end	
	
	gre.set_data(data)
end

