local screenSize = {}
local screenKeys = {'screen_width', 'screen_height'}
local cyclesCompleted = 0
local cyclesNeeded = 4
local cycleLen = 2000
local updatesRemaining = 0
local seed
local RNGSeed = 1
local i = 1
local cloneTable = {}
local controlName
local fpsMeasured = true

local sampleFPS = 0;
local sampleDuration = 500; --frames are incremented on each render, sampleDuration says how many updates to average that data over before displaying
local lastSampledTime = 0;
local sampleFrames = 0;

local totalFrames = 0
local startTime = nil
local currentTime = 0

local function resetFramework()
  startTime = currentTime
  sampleFPS = 0;
  lastSampledTime = 0;
  sampleFrames = 0;
  totalFrames = 0
  cyclesCompleted = 0
  updatesRemaining = cycleLen
  i = 1
  
    -- Delete all the objects from our previous test
  for index, v in pairs(cloneTable) do
    gre.delete_object(controlName .. '_' .. index)
  end
  cloneTable = {}
end

local function calculateFramerate()
  sampleFrames = sampleFrames + 1
  totalFrames = totalFrames + 1
  local diff = currentTime - lastSampledTime
  
  if diff >= sampleDuration then
    sampleFPS = sampleFrames/(diff/1000)
    sampleFPS = math.floor(sampleFPS)
    sampleFrames = 0
    lastSampledTime = currentTime;
  end
  
  updatesRemaining = updatesRemaining - 1
end

local count = 0
function CBTimerUpdate(mapargs)
  count = count + 1
  --First thing we do is update the current time, everyone else should refer to this instead of using gre.mstime() again.
  currentTime = gre.mstime()
  
  if startTime == nil then
    resetFramework()
    if cyclesCompleted == 0 then
      seed = RNGSeed or currentTime
    end
    
    math.randomseed(seed)
    gre.send_event('timer.update')
    gre.set_value('active_layer.fill_0.grd_hidden',1)
    gre.set_value('active_layer.rect_0.grd_hidden',1)
    gre.set_value('active_layer.poly_0.grd_hidden',1)
    gre.set_value('active_layer.img_0.grd_hidden',1)
    screenSize = gre.env(screenKeys)
    return
  end
  
  local NumGenerated = math.random(0,100000)
  local fps = gre.get_value('grd_fps')
  
  if fps then
    fpsMeasured = true
    gre.set_value('fps', fps)
  elseif fpsMeasured then
    gre.set_value('fps', sampleFPS)  
  elseif fpsMeasured == false then
    gre.redraw()
  end
  
  local CurScreen = mapargs.context_screen
  local complete = CloneAndMove(NumGenerated, CurScreen)
  
  if complete then 
    local elapsedTime = currentTime - startTime
    local fps = totalFrames / (elapsedTime/1000)
    --print("Total Frames:", totalFrames, "Seconds:", elapsedTime/1000)
    gre.log_perf_stat("Snow_v2", controlName, fps, "fps")
    
    --Indicate that we need a resetFramework() on our next update.
    startTime = nil
    
    gre.send_event('timer.complete')
  else
    gre.send_event('timer.update')
  end
end

function CloneAndMove(randomNumber, currentScreen)
  calculateFramerate()
  
  if updatesRemaining == 0 and cyclesCompleted < cyclesNeeded then
    cyclesCompleted = cyclesCompleted + 1
    updatesRemaining = cycleLen
    return false
  elseif cyclesCompleted >= cyclesNeeded then
    return true
  end
  
  local frequency
  if cyclesCompleted == 0 then
    frequency = 180
  elseif cyclesCompleted == 1 then
    frequency = 90
  elseif cyclesCompleted == 2 then
    frequency = 60
  elseif cyclesCompleted == 3 then
    frequency = 30
  else
    frequency = 1
  end
  
  local data = {}
  data.hidden = 0
  data.y = -50
  data.x = (randomNumber % screenSize[screenKeys[1]]) - 25
  if currentScreen == 'Screen1' then
    controlName = 'fill'
  elseif currentScreen == 'Screen2' then
    controlName = 'rect'
  elseif currentScreen == 'Screen3' then
    controlName = 'poly'
  end
  if randomNumber % frequency == 0 then
    gre.clone_object(controlName .. '_0', controlName .. '_' .. i, 'active_layer', data)
    cloneTable[i] = true
    i = i + 1
  end  
  
  for index, v in pairs(cloneTable) do
    local curY = (gre.get_control_attrs(controlName .. '_' .. index, 'y'))['y']
    local data = {}
    data['active_layer.' .. controlName .. '_' .. index .. '.grd_y'] = curY + 1
    gre.set_data(data)
    if curY >= screenSize[screenKeys[2]] then
      gre.delete_object(controlName .. '_' .. index)
      cloneTable[index] = nil
    end
  end
  
  return false
end