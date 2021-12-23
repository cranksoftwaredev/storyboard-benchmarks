
local STAGE = { 
	width = 480,
	height = 640 
	}
local FRAMERATE = 60
local context = nil
local header = nil

-- By default we run as a purely event driven activity.  If this flag is
-- changed to false, then we will run as a timer based application which 
-- doesn't scale as well for high to low end platforms.
local runEventBased = true
local perfLogMSDelay = 3000

-- By default after we generate the performance log information we quit
local quitAfterPerf = true

-- Seed the random number generator with a consistent value, set to nil for really random
local RNGSeed = 1
if(RNGSeed == nil) then
  RNGSeed = gre.mstime()
end
math.randomseed(RNGSeed)

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
		gre.log_perf_stat("Raiden", "Raiden", sampleFPS, "fps")
		perfLogMSDelay = 0
		if(quitAfterPerf) then
			gre.send_event("gre.quit")
		end
	end	
end

function updateFPS()
	local data = {}
	data["fps"] = tostring(sampleFPS)
	gre.set_data(data)
end

function init()
	local data = {}
	data["timer_interval"] = 1000 / FRAMERATE
	gre.set_data(data)
		
	--//initialize test variables
	gameTime = getTimer()+30000
	
	if(runEventBased) then
		gre.send_event("timer.tick")
	else
		gre.send_event("start_timer")
	end
end


local  gameTime = 0;
function loop()
	gameTime = getTimer()+30000
	
	drawGround()
	drawPlanesBackdrop()
	drawClouds()
	drawEnemies()
	drawBullets()
	drawShip()
	
	--header.updatePerformance();
	calculateFramerate()
	
	if(runEventBased) then
		gre.send_event("timer.tick")
	end
end

function drawGround(tick)
	local tilesize = 128
	local tileHeights = math.ceil(STAGE.height / tilesize) *tilesize
	local tileBaseY = math.floor(gameTime/60) % tileHeights
	
	
	local tileY = tileBaseY
	while(tileY-tilesize > -tilesize) do
		tileY = tileY - tilesize
	end

	local data = {}

	data["ground_layer.ground_tile.grd_y"] = tileY
	gre.set_data(data)	
end



local backdropIndex = 0
local backdrops = {}

function drawPlanesBackdrop(diff)
	local shipCount = math.floor(gameTime / 2000)
	local half = STAGE.width/2
	local ship 
	local i
	
	while(backdropIndex < shipCount) do
		backdropIndex = backdropIndex + 1;
		ship = GameObject:new()
		ship.time = backdropIndex*2000
		ship.width = 48
		ship.height = 48
		ship.x = math.random()*(half-48)
		table.insert(backdrops, ship)
		ship = GameObject:new()
		ship.time = 1000 + backdropIndex*2000
		ship.width = 48
		ship.height = 48
		ship.x = half + (math.random()*(half-48));
		table.insert(backdrops, ship)
	end
	
	for i=table.maxn(backdrops),1,-1 do
		ship = backdrops[i]
		ship.y = (gameTime-ship.time) / 33
		ship.y = ship.y - ship.height
		if(ship.y > STAGE.height+ship.height) then
			table.remove(backdrops, i)
		else
			local data = {}
			local ship_prefix= "plane_layer.plane"
			data[ship_prefix..i..".grd_x"] = math.floor(ship.x)
			data[ship_prefix..i..".grd_y"] = math.floor(ship.y)
			gre.set_data(data)
			--context.drawImage(assets.Ship3, Math.floor(ship.x), Math.floor(ship.y));
		end
	end
end


local cloudIndex = 0
local clouds = {}

function drawClouds(diff)
	local cloudCount = math.floor(gameTime / 3000)
	local half = STAGE.width/2
	local cloud
	
	while(cloudIndex < cloudCount) do
		cloudIndex = cloudIndex + 1
		cloud = GameObject:new()
		cloud.time = cloudIndex*3000
		cloud.width = 128
		cloud.height = 128
		cloud.x = math.random()*(half-128)
		table.insert(clouds, cloud)
		cloud = GameObject:new()
		cloud.time = 1500 + cloudIndex*3000
		cloud.width = 128
		cloud.height = 128
		cloud.x = half + (math.random()*(half-128))
		table.insert(clouds, cloud)
	end

	for i=table.maxn(clouds),1,-1 do
		cloud = clouds[i];
		cloud.y = (gameTime-cloud.time) / 20;
		cloud.y = cloud.y - cloud.height;
		if(cloud.y > STAGE.height+cloud.height) then
			table.remove(clouds, i)
		else
			local data = {}
			local cloud_prefix= "cloud_layer.cloud"
			data[cloud_prefix..i..".grd_x"] = math.floor(cloud.x)
			data[cloud_prefix..i..".grd_y"] = math.floor(cloud.y)
			gre.set_data(data)
		end
	end
end

local enemyIndex = 0
local enemies = {}

function drawEnemies(diff)
	local shipCount = math.floor(gameTime / 500)
	while(enemyIndex < shipCount) do
		enemyIndex = enemyIndex + 1
		local ship = GameObject:new()
		ship.time = enemyIndex*500;
		ship.width = 64;
		ship.height = 64;
		ship.x = math.random()*(STAGE.width-64);
		table.insert(enemies, ship)
	end
	for i=table.maxn(enemies),1,-1 do
		local ship = enemies[i];
		ship.y = (gameTime-ship.time) / 5;
		ship.y = ship.y - ship.height;
		if(ship.y > STAGE.height+ship.height) then
			table.remove(enemies, i)
		else
			local data = {}
			local enemie_prefix= "enemy_ship_layer.enemy_ship"
			data[enemie_prefix..i..".grd_x"] = math.floor(ship.x)
			data[enemie_prefix..i..".grd_y"] = math.floor(ship.y)
			gre.set_data(data)		
			--context.drawImage(assets.Ship2, Math.floor(ship.x), Math.floor(ship.y));
			drawEnemyBullets(ship);
		end
	end
end

local bullet_list = {}
local NUM_BULLETS = 39

function get_bullet()
	local i
	
	for i=1,NUM_BULLETS,1 do
		if bullet_list[i] == nil or bullet_list[i] == 0 then
			bullet_list[i] = 1
			return i
		end
	end
	return 0
end

function release_bullet(num)
	bullet_list[num] = 0
end 


function drawEnemyBullets(ship)
	local bulletCount = math.floor((gameTime-ship.time) / 500);
	local bullet;
	local down = (math.pi)/2;
	while(ship.bulletCount < bulletCount) do
		ship.bulletCount = ship.bulletCount + 1
		bullet = GameObject:new()
		bullet.bullet_num = get_bullet()
		bullet.time = ship.time + (ship.bulletCount*500)
		bullet.width = 20
		bullet.height = 20
		bullet.angle = down - 0.5
		table.insert(ship.bullets, bullet)
		
		bullet = GameObject:new()
		bullet.bullet_num = get_bullet()
		bullet.time = ship.time + (ship.bulletCount*500)
		bullet.width = 20
		bullet.height = 20
		bullet.angle = down
		table.insert(ship.bullets, bullet)
		
		bullet = GameObject:new()
		bullet.bullet_num = get_bullet()
		bullet.time = ship.time + (ship.bulletCount*500)
		bullet.width = 20
		bullet.height = 20
		bullet.angle = down + 0.5
		table.insert(ship.bullets, bullet)
	end
	for i=table.maxn(ship.bullets),1,-1 do
		bullet = ship.bullets[i]
		local distance = (gameTime-bullet.time) / 4
		bullet.x = ship.x + 22 + (math.cos(bullet.angle)*distance)
		bullet.y = ship.y + ship.height + (math.sin(bullet.angle)*distance)
		if(bullet.y > STAGE.height+bullet.height) then
			release_bullet(bullet.bullet_num)
			table.remove(ship.bullets, i)
		elseif bullet.bullet_num ~= 0 then
			local data = {}
			local enemie_bullet_prefix= "enemy_ship_layer.enemy_bullet"
			data[enemie_bullet_prefix..bullet.bullet_num..".grd_x"] = math.floor(bullet.x)
			data[enemie_bullet_prefix..bullet.bullet_num..".grd_y"] = math.floor(bullet.y)
			gre.set_data(data)			
			--context.drawImage(assets.EnemyBullet, Math.floor(bullet.x), math.floor(bullet.y));
		end
	end
end

local bulletIndex = 0
local bullets = {}

function drawBullets(diff)
	local bulletCount = math.floor(gameTime / 100)
	while(bulletIndex < bulletCount) do
		bulletIndex = bulletIndex + 1
		local bullet = GameObject:new()
		bullet.time = bulletIndex*100
		bullet.width = 20
		bullet.height = 20
		local freq = gameTime % 3000
		local usableWidth = STAGE.width-64;
		if(freq < 1500) then
			bullet.x = (freq/1500)*usableWidth
		else
			freq = freq - 1500;
			bullet.x = usableWidth-((freq/1500)*usableWidth)
		end
		bullet.x = bullet.x + 20;
		table.insert(bullets, bullet)
	end

	for i=table.maxn(bullets),1,-1 do
		local bullet = bullets[i]
		local offset = (gameTime-bullet.time) / 2
		bullet.y = STAGE.height - 64 - offset
		if(bullet.y < -bullet.height) then
			table.remove(bullets, i)
		else
			local data = {}
			local bullet_prefix= "fighter_ship_layer.bullet"
			data[bullet_prefix..i..".grd_x"] = math.floor(bullet.x)
			data[bullet_prefix..i..".grd_y"] = math.floor(bullet.y)
			gre.set_data(data)			
			--context.drawImage(assets.Bullet, Math.floor(bullet.x), Math.floor(bullet.y));
		end
	end
end

local player = nil
function drawShip()
	if(player == nil) then
		player = GameObject:new()
		player.width = 64
		player.height = 64
		player.y = STAGE.height - player.height;
	end
	local freq = gameTime % 3000;
	local usableWidth = STAGE.width-player.width;
	if(freq < 1500) then
		player.x = (freq/1500)*usableWidth;
	else
		freq = freq - 1500;
		player.x = usableWidth-((freq/1500)*usableWidth);
	end
	
	local data = {}
	local fighter_prefix= "fighter_ship_layer.fighter_ship"
	data[fighter_prefix..".grd_x"] = math.floor(player.x)
	data[fighter_prefix..".grd_y"] = math.floor(player.y)
	gre.set_data(data)		
	--context.drawImage(assets.Ship1, Math.floor(player.x), Math.floor(player.y));
end

module("GameObject", package.seeall)

function GameObject:new(o) 
	local newGameObject = {}
	setmetatable(newGameObject, self)
	self.__index = self

	newGameObject.x = 0
	newGameObject.y = 0
	newGameObject.width = 0;
	newGameObject.height = 0;
	newGameObject.time = 0;
	
	newGameObject.bulletCount = 0
	newGameObject.bullets = {}
	
	newGameObject.angle = 0
	newGameObject.bullet_num = 0
	
	return newGameObject
end
