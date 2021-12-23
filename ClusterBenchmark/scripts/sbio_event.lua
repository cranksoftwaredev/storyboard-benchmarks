--[[
This is a modification of the StoryboardIO cluster but adjusted to run a series of visual changes
to measure performance scenarios.  The performance of the cluster is measured in distinct stages
- Stage 1:
* Only the speedometer is updated
- Stage 2:
* Only the tell tales are updated
- Stage 3:
* Both the speedometer and the tell tales are updated
- Stage 4:
* Speedometer, tell tales and other indicators updates
]]--

-- By default we run as a purely event driven activity.  If this flag is
-- changed to false, then we will run as a timer based application which 
-- doesn't scale as well for high to low end platforms.
local runEventBased = true
local perfLogMSDelay = 3000

-- By default after we generate the performance log information we quit
local quitAfterPerf = true

local numSamples = 0

---
-- Speed & RPM Needles
---
local gSpeed = 10
local gSpeedDirection = 1
local gRPM = 0
local function UpdateSpeedAndRPM()
  gSpeed = gSpeed + gSpeedDirection
  if(gSpeed > 190 or gSpeed < 10) then
    gSpeedDirection = -1 * gSpeedDirection
  end
  -- Scale RPM based on speed
  gRPM = (9500 / 180) * gSpeed
  
  local speed_rot = (gSpeed * (214/200)) - 107
  local rpm_rot = (gRPM / 10000) * 49
  
  local data = {}
  data["speedometer.pointer_speedometer.rot"] = speed_rot 
  data["tach_exterior.pointer_tach_exterior.rot"] = rpm_rot
  
  gre.set_data(data)
end

-- This assumes that the speed has already been set
local function UpdateSpeedText()
  gre.set_value("speedometer_content.speed.text", tostring(gSpeed))
end

---
-- GAS Gauges
---
local gGasLevel = 0
local gGasDirection = 1

local function UpdateGas()
  gGasLevel = gGasLevel + gGasDirection
  if(gGasLevel < 0) then
    gGasLevel = 0
    gGasDirection = 1
  elseif(gGasLevel > 10) then
    gGasLevel = 10
    gGasDirection = -1
  end
  
  local data = {}
  for i=1,10 do
    key = string.format("gas_exterior.full_%d.grd_hidden", i)
    if(i < gGasLevel) then
      data[key] = false
    else
      data[key] = true
    end
  end
  gre.set_data(data)
end 

---
-- Battery Levels
---
local gBatteryLevel = 0
local gBatteryDirection = 1
local function UpdateBattery()
  gBatteryLevel = gBatteryLevel + gBatteryDirection
  if(gBatteryLevel < 0) then
    gBatteryLevel = 0
    gBatteryDirection = 1
  elseif(gBatteryLevel > 10) then
    gBatteryLevel = 10
    gBatteryDirection = -1
  end
  
  local data = {}
  for i=1,10 do
    key = string.format("battery.bat_%d.grd_hidden", i + 7)
    if(i < gBatteryLevel) then
      data[key] = false
    else
      data[key] = true
    end
  end
  gre.set_data(data)
end 

---
-- Oil Levels
---
local gOilLevel = 0
local gOilDirection = 1
local function UpdateOil()
  gOilLevel = gOilLevel + gOilDirection
  if(gOilLevel < 0) then
    gOilLevel = 0
    gOilDirection = 1
  elseif(gOilLevel > 9) then
    gOilLevel = 9
    gOilDirection = -1
  end
  
  local data = {}
  for i=1,10 do
    
    key = string.format("oil.%d_glow.grd_hidden", i)
    if(i < gBatteryLevel) then
      data[key] = false
    else
      data[key] = true
    end
  end
  gre.set_data(data)
end 

---
-- Indicators
---
local gCurrentIndicator = 0
local IndicatorList = {
"L_arrow_glow",
"R_arrow_glow",
"swerve_glow",
"brake_glow",
"highbeam_glow",
"engine_glow",
"seatbelt_glow",
"ABS_glow"
};

local function UpdateIndicator() 
  local lastIndicator = gCurrentIndicator
  gCurrentIndicator = gCurrentIndicator + 1
  if(gCurrentIndicator > #IndicatorList) then
    gCurrentIndicator = 0
  end
  
  local data = {}
  if(IndicatorList[lastIndicator]) then
    data[string.format("indicators.%s.grd_hidden", IndicatorList[lastIndicator])] = false
  end
  if(IndicatorList[gCurrentIndicator]) then
    data[string.format("indicators.%s.grd_hidden", IndicatorList[gCurrentIndicator])] = true
  end
  gre.set_data(data)
end

local CurrentStage = 1
local StageUpdates = {
{ label="Indicators", UpdateIndicator },
{ label="Dials", UpdateSpeedAndRPM},
{ label="DialsAndText", UpdateSpeedAndRPM, UpdateSpeedText },
{ label="DialsAndIndicators", UpdateSpeedAndRPM, UpdateIndicator },
{ label="DialsAndTextAndIndicators", UpdateSpeedAndRPM, UpdateSpeedText, UpdateIndicator },
{ label="Everything", UpdateSpeedAndRPM, UpdateSpeedText, UpdateIndicator, UpdateBattery, UpdateGas, UpdateOil },
}

--- @param gre#context mapargs
function CBUpdateFrame(mapargs)
  local now = gre.mstime(true)
  numSamples = numSamples + 1

  -- Update the frame count and the visuals
  local updates = StageUpdates[CurrentStage]
  for i=1,#updates do
    updates[i]()
  end
  
  -- Determine if we are reporting or not  
  if((perfLogMSDelay ~= 0) and ((now - startTime) > perfLogMSDelay)) then
    local sampleFPS = numSamples / ((now - startTime) / 1000)
    
    gre.log_perf_stat("Cluster", updates.label, sampleFPS, "ups")
    
    CurrentStage = CurrentStage + 1
    if(CurrentStage <= #StageUpdates) then
      startTime = gre.mstime(true)
      numSamples = 0
    elseif(quitAfterPerf) then
      gre.send_event("gre.quit")
    end  
  end  

  --Assuming we are unthrottled events
  if(runEventBased) then
    gre.send_event("UpdateFrame")
  end
end

--- @param gre#context mapargs
function CBStartBenchmark(mapargs) 
  gre.send_event("UpdateFrame")
  startTime = gre.mstime(true)
end






