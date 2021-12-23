require("FramedBitmap")

-- By default we run as a purely event driven activity.  If this flag is
-- changed to false, then we will run as a timer based application which 
-- doesn't scale as well for high to low end platforms.
local perfLogMSDelay = 3000

-- By default after we generate the performance log information we quit
local quitAfterPerf = true

-- Seed the random number generator with a consistent value, set to nil for really random
local RNGSeed = 1
if(RNGSeed == nil) then
  RNGSeed = gre.mstime()
end
math.randomseed(RNGSeed)

local Bomb = {
	"images/explosion/e_f01.png",
	"images/explosion/e_f02.png",
	"images/explosion/e_f03.png",
	"images/explosion/e_f04.png",
	"images/explosion/e_f05.png",
	"images/explosion/e_f06.png",
	"images/explosion/e_f07.png",
	"images/explosion/e_f08.png"
}

local EnemySouth = {
	"images/monster/s1.png",
	"images/monster/s2.png",
	"images/monster/s3.png"
}

local EnemyEast = {
	"images/monster/e1.png",
	"images/monster/e2.png",
	"images/monster/e3.png"
}

local EnemyWest = {
	"images/monster/w1.png",
	"images/monster/w2.png",
	"images/monster/w3.png"
}

local EnemyNorth = {
	"images/monster/n1.png",
	"images/monster/n2.png",
	"images/monster/n3.png"
}

local MONSTER_BASE = "monster_layer.monstercopy"
local BOMB_BASE = "lighthouse_layer.bombcopy"
local LASER_BASE = "lighthouse_layer.laser.points"

local meter
local fps
local draw
local results
local monsters = {}
local explosions = {}

local NUM_MONSTERS = 600
local NUM_EXPLOSIONS = 8

function cb_init()
	local R = math.pi/180
	local i
	
	--create monsters
	for i=1,NUM_MONSTERS,1 do
		local speed = 3+(math.random()*2)
		local angle = math.random()*360
		
		local fb = nil
		if (angle >= 45 and angle < 135) then
			fb = FramedBitmap:new(EnemySouth)
		elseif(angle >= 135 and angle < 225) then
			fb = FramedBitmap:new(EnemyWest)
		elseif(angle >= 225 and angle < 315) then
			fb = FramedBitmap:new(EnemyNorth)
		else
			fb = FramedBitmap:new(EnemyEast)
		end
		
		fb.x = math.random()*1200
		fb.y = math.random()*600
		fb.xMove = math.cos(angle*R)*speed
		fb.yMove = math.sin(angle*R)*speed
		fb.scale = 0.5+(math.random()*0.7)
		--fb.randomize()
		fb.frame = math.floor(math.random()*table.maxn(fb.bitmaps))
		table.insert(monsters, fb)
	end
	
	--create explosions
	for i=1,NUM_EXPLOSIONS,1 do
		local fb = FramedBitmap:new(Bomb)
		fb.frame = i
		fb.x = -200
		fb.y = -200
		table.insert(explosions, fb)
	end
			
	--meter = new FPSMeter()
	--setInterval("processFrame()", 17);
	gre.send_event("start_timer")
	gre.send_event("screen_update")
end


function cb_processFrame()
	local i 
	local data = {}
	
	--position monsters
	for i=1,table.maxn(monsters),1 do
		local fb = monsters[i]
		fb.x = fb.x + fb.xMove
		fb.y = fb.y + fb.yMove
		
		if(fb.x < -40) then
			fb.x = fb.x + 1240
		elseif(fb.x > 1200) then
			fb.x = fb.x - 1240
		end
		
		if(fb.y < -40) then
			fb.y = fb.y + 640
		elseif(fb.y > 600) then
			fb.y = fb.y - 640
		end

		data[MONSTER_BASE..i..".grd_x"] = math.floor(fb.x/fb.scale)
		data[MONSTER_BASE..i..".grd_y"] = math.floor(fb.y/fb.scale)
		data[MONSTER_BASE..i..".grd_width"] = 64 * fb.scale
		--data[MONSTER_BASE..i..".image"] = fb:getNextBitmap()
		fb.frame = fb.frame + 1
		if(fb.frame > table.maxn(fb.bitmaps)) then
			fb.frame = 1;
		end
		data[MONSTER_BASE..i..".image"] = fb.bitmaps[fb.frame]
	end
	
	--draw laser and explosions
	for i=1,NUM_EXPLOSIONS,1 do
		local fb = explosions[i]
		if(fb.frame == 1) then
			local dist = 200;
			local angle = math.random()*360*math.pi/180;
			fb.x = 520+(math.cos(angle)*dist);
			fb.y = 270+(math.sin(angle)*dist);
			
			data[LASER_BASE] = "612:180 "..math.floor(fb.x+83)..":"..math.floor(fb.y+70)
		end
		data[BOMB_BASE..i..".grd_x"] = math.floor(fb.x)
		data[BOMB_BASE..i..".grd_y"] = math.floor(fb.y)
		--data[BOMB_BASE..i..".image"] = fb:getNextBitmap()
		fb.frame = fb.frame + 1
		if(fb.frame > table.maxn(fb.bitmaps)) then
			fb.frame = 1;
		end
		data[BOMB_BASE..i..".image"] = fb.bitmaps[fb.frame]		
	end
	
	gre.set_data(data)

	--updatePerformance()
	calculateFramerate()
	
	gre.send_event("screen_update")
end


local startTime
function getTimer()
	if(startTime == nil) then
		startTime = gre.mstime()
	end
	
	return  math.floor(gre.mstime() - startTime)
end

local sampleFPS = 0;
local sampleDuration = 500; --frames are incremented on each render, sampleDuration says how many milliseconds to average that data over before displaying
local lastSampledTime = 0;
local sampleFrames = 0;

local totalFPS = 0
local numSamples = 0

function calculateFramerate()
	sampleFrames = sampleFrames + 1
	local diff = getTimer() - lastSampledTime;
	
	if diff >= sampleDuration then
		local rawFPS = sampleFrames/(diff/1000)
		sampleFPS = math.floor(rawFPS*100)/100 --format as XX.XX
		sampleFrames = 0;
		lastSampledTime = getTimer();
		
		totalFPS = totalFPS + sampleFPS
		numSamples = numSamples + 1
	end
	
	if((perfLogMSDelay ~= 0) and (getTimer() > perfLogMSDelay)) then
		gre.log_perf_stat("BitmapGame", "BitmapGame", sampleFPS, "fps")
		perfLogMSDelay = 0
		if(quitAfterPerf == true) then
			gre.send_event("gre.quit")
		end
	end	
end

function cb_updateFPS()
	local data = {}
	
	data["fps"] = tostring(sampleFPS)
	gre.set_data(data)
end
