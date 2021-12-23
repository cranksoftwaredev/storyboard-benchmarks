local SAMPLE_DURATION = 500; -- frames are incremented on each render, sampleDuration says how many milliseconds to average that data over before displaying
local TARGET_FPS = 60
local RUN_TIME = 20 -- seconds
local NUM_SCREENS = 4

local gSampleFrames = 0
local gLastSampledTime = 0
local gSampleFPS = 0
local gTotalFPS = 0
local gNumSamples = 0
local gRotValue = 0
local gCurrentTime = 0
local gCurScreen


local gTestDescription = {
  "unscaled_custom_center",
  "scaled_custom_center",
  "unscaled_at_center",
  "scaled_at_center",
}

local gStartTime

-- Simple performance log print out wrapper
if(not gre.log_perf_stat) then
  gre.log_perf_stat = function(test, qualifier, result, description)
    print("PERF: " .. test .. ", " .. qualifier .. ", " .. tostring(result) .. ", " .. description);
  end
end

function sendTick()
  gre.send_event("send_tick")
end

function rotateValue()
  gRotValue = gRotValue + 5
  gre.set_value("rot", gRotValue)
end

function calculateFramerate()
  gSampleFrames = gSampleFrames + 1
  gCurrentTime = gre.mstime()
  local diff = gCurrentTime - gLastSampledTime;

  if diff >= SAMPLE_DURATION then
    gSampleFPS = gSampleFrames/(diff/1000)
    gSampleFrames = 0
    gLastSampledTime = gCurrentTime;
    gNumSamples = gNumSamples + 1
    gTotalFPS = gTotalFPS + gSampleFPS
  end

  rotateValue()
  -- advance frames as fast as possible
  sendTick()
end

--- @param gre#context mapargs
function CBDone(mapargs)
  local FPS = gTotalFPS / gNumSamples
  gre.log_perf_stat("RotationBenchmark", gTestDescription[gCurScreen], FPS, "fps")

  if (gCurScreen == NUM_SCREENS) then
    gre.send_event("quit")
    return
  end

  -- next case
  gCurScreen = gCurScreen + 1
  gre.send_event(string.format("screen%i", gCurScreen))
end

--- @param gre#context mapargs
function CBPreTest(mapargs)
  gSampleFrames = 0
  gLastSampledTime = 0
  gSampleFPS = 0
  gTotalFPS = 0
  gNumSamples = 0
  gRotValue = 0
  gre.set_value("rot", gRotValue)
  gStartTime = gre.mstime()
end

--- @param gre#context mapargs
function CBInit(mapargs)
  local data = {}
  data["runTime"] = RUN_TIME * 1000
  local tick = math.floor(1000/TARGET_FPS)
  data["tickRepeat"] = tick

  gCurScreen = 1
  gre.set_data(data)
end
