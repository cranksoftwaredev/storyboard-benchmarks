--
-- sbperftest.lua
--
-- The 'sbperftest' lua module is a lua module that is intended to be included
-- in all performance test scenarios. This module includes common code that
-- is used to measure various performance metrics.
--
-- The master version of this file lives in SVN at:
-- benchmarks/PerfGeneral/scripts/sbperftest.lua
--
-- The following actions should be defined. The actions marked with a * are
-- mandatory. All actions are typically defined in the Application context,
-- except for 'test.completed', which is defined in the Screen context.
--
-- gre.screenhide.pre -> gra.lua: CBScreenHidePre()
-- gre.screenhide.post -> gra.lua: CBScreenHidePost()
-- gre.screenshow.pre -> gra.lua: CBScreenShowPre()
-- *gre.screenshow.post -> gra.lua: CBScreenShowPost()
-- *test.update -> gra.lua: CBUpdate()
-- *test.step_pre -> gra.lua: CBStepPre()
-- *test.step -> gra.lua: CBStep()
-- test.completed -> gra.sendevent: gre.quit OR gra.screen: [next_screen]
--
-- API functions:
-- sbperftest.RegisterPerfTest(name, callbacks, [duration])
--
-- This function registers a perftest with under 'name', which must match the screen name for the
-- corresponding performance test scenario
--
-- The 'callbacks' parameter is a table containing the following function callbacks that are called if
-- the entry exists:
-- * CBUpdate(mapargs, elapsedTime) - function called on every iteration during the duration of the test
-- * CBSetup(mapargs) - called on gre.screenshow.post, the test is kicked off immediately following this callback
-- * CBTeardown(mapargs) - called on gre.screenhide.pre
-- * CBPreSetup(mapargs) - called on gre.screenshow.pre
-- * CBPostTeardown(mapargs) - called on gre.screenhide.post
--
-- 'duration' is an optional parameter specifying a duration  of the test (in ms) which will override
-- the default duration of 10 seconds. 
--
-- For each screen in the test, a lua script file should be created defining the necessary callbacks
-- and registering the test. To include this framework, use 'require "perftest"' for each lua script. 
--
-- An example script file is show below:
--
--[[
-- screen_name.lua

require "sbperftest"

local screen_name = {}

function screen_name.CBUpdate(mapargs, elapsedTime)
    -- update variables here to drive redraw
end

sbperftest.RegisterPerfTest("screen_name", screen_name)
--]]

local DEFAULT_PERF_TEST_TIME = 5000
local DEFAULT_PERF_TEST_STEPS = 1
local startTime = gre.mstime()

local measureSampleDuration = 500;
local measureLastSampleTime = 0;
local measureSampleFrameAccum = 0;

local measureSampleCount = 0;
local measureFpsSum = 0
local measureFpsMin = math.huge
local measureFpsMax = 0

local ScreenMeasureSampleCount = 0;
local ScreenMeasureFpsSum = 0
local ScreenMeasureFpsMin = math.huge
local ScreenMeasureFpsMax = 0

local MeasureFramerate = function (elapsedTime)
    measureSampleFrameAccum = measureSampleFrameAccum + 1
    local sampleTime = elapsedTime - measureLastSampleTime
--    print(string.format("%d/%0.4f", measureSampleFrameAccum, sampleTime))

    if (sampleTime >= measureSampleDuration) then
        local fps = measureSampleFrameAccum/(sampleTime/1000)
        -- reset accumulators
        measureLastSampleTime = elapsedTime
        measureSampleFrameAccum = 0

        -- update stats
        measureSampleCount = measureSampleCount + 1
        measureFpsSum = measureFpsSum + fps
        measureFpsMin = math.min(measureFpsMin, fps)
        measureFpsMax = math.max(measureFpsMax, fps)
        local measureFpsAvg = measureFpsSum / measureSampleCount
--        print(string.format("%0.2f/%0.2f/%d/%0.2f/%0.2f/%0.2f", fps, measureFpsSum, measureSampleCount, measureFpsMin, measureFpsMax, measureFpsAvg))
    end
end

local MeasuredResultSummary = function (appName, testName, stepNumber)
    testName = testName .. '_ups' .. ' step ' .. stepNumber;
    local fpsMin = measureFpsMin
    local fpsMax = measureFpsMax
    local fpsAvg = measureFpsSum / measureSampleCount
    if measureSampleCount > 0 then
      gre.log_perf_stat(appName, testName, fpsAvg, "ups")
      gre.log(-1, string.format("PERF3: %s,%s: %0.5f/%0.5f/%0.5f (%d samples)", appName, testName, fpsMin, fpsMax, fpsAvg, measureSampleCount))
    end
end

local MeasuredResultReset = function ()
    startTime = gre.mstime()
    measureLastSampleTime = 0;
    measureSampleFrameAccum = 0;

    measureSampleCount = 0
    measureFpsSum = 0
    measureFpsMin = math.huge
    measureFpsMax = 0
end

local ScreenMeasureFpsUpdate = function ()
    ScreenMeasureFpsSum = ScreenMeasureFpsSum + measureFpsSum
    ScreenMeasureSampleCount = ScreenMeasureSampleCount + measureSampleCount
    ScreenMeasureFpsMax = math.max(ScreenMeasureFpsMax, measureFpsMax)
    ScreenMeasureFpsMin = math.min(ScreenMeasureFpsMin, measureFpsMin)
end

local ScreenMeasuredResultSummary = function (appName, testName)
    testName = testName .. '_ups';
    local fpsMin = ScreenMeasureFpsMin
    local fpsMax = ScreenMeasureFpsMax
    local fpsAvg = ScreenMeasureFpsSum / ScreenMeasureSampleCount
    if ScreenMeasureSampleCount > 0 then
      gre.log_perf_stat(appName, testName, fpsAvg, "ups")
      gre.log(-1, string.format("PERF3: %s,%s: %0.5f/%0.5f/%0.5f (%d samples)", appName, testName, fpsMin, fpsMax, fpsAvg, ScreenMeasureSampleCount))
    end
end

local ScreenMeasuredResultReset = function ()
    ScreenMeasureSampleCount = 0
    ScreenMeasureFpsSum = 0
    ScreenMeasureFpsMin = math.huge
    ScreenMeasureFpsMax = 0
end

sbperftest = {}

local perfTestData = {}
local perfTestTestTime = DEFAULT_PERF_TEST_TIME
local perfTestSteps = DEFAULT_PERF_TEST_STEPS
local perfTestStepsCompleted = 0
local perfTestCallbackScreenCacheUpdate = nil

local perfResultSampleCount = 0
local perfResultSum = 0
local perfResultMin = math.huge
local perfResultMax = 0

local ScreenPerfResultSampleCount = 0
local ScreenPerfResultSum = 0
local ScreenPerfResultMin = math.huge
local ScreenPerfResultMax = 0

local PerfResultSummary = function (appName, testName, stepNumber)
    testName = testName .. '_fps' .. ' step ' .. stepNumber;
    local fpsMin = perfResultMin
    local fpsMax = perfResultMax
    local fpsAvg = perfResultSum / perfResultSampleCount
    if perfResultSampleCount > 0 then
      gre.log_perf_stat(appName, testName, fpsAvg, "fps")
      print(string.format("PERF2: %s,%s: %0.5f/%0.5f/%0.5f (%d samples)", appName, testName, fpsMin, fpsMax, fpsAvg, perfResultSampleCount))
    end
end

local PerfResultReset = function ()
    perfResultSampleCount = 0
    perfResultSum = 0
    perfResultMin = math.huge
    perfResultMax = 0
end

local ScreenPerfResultSummary = function (appName, testName)
    testName = testName .. '_fps';
    local fpsMin = ScreenPerfResultMin
    local fpsMax = ScreenPerfResultMax
    local fpsAvg = ScreenPerfResultSum / ScreenPerfResultSampleCount
    if ScreenPerfResultSampleCount > 0 then
      gre.log_perf_stat(appName, testName, fpsAvg, "fps")
      print(string.format("PERF2: %s,%s: %0.5f/%0.5f/%0.5f (%d samples)", appName, testName, fpsMin, fpsMax, fpsAvg, ScreenPerfResultSampleCount))
    end
end

local ScreenPerfResultReset = function ()
    ScreenPerfResultSampleCount = 0
    ScreenPerfResultSum = 0
    ScreenPerfResultMin = math.huge
    ScreenPerfResultMax = 0
end

function CBScreenShowPre(mapargs) 
    local screenShown = mapargs and mapargs.context_event_data and mapargs.context_event_data.name
    if type(perfTestData[screenShown]) == 'table' then 

        if type(perfTestData[screenShown].callbacks) == 'table' then
            -- callout to pre-setup code
            if perfTestData[screenShown].callbacks.CBPreSetup then
                perfTestData[screenShown].callbacks.CBPreSetup(mapargs)
            end
        end
    end
end

function CBScreenShowPost(mapargs) 
    local screenShown = mapargs and mapargs.context_event_data and mapargs.context_event_data.name
    if type(perfTestData[screenShown]) == 'table' then 

        -- update test time
        if type(perfTestData[screenShown].testTime) == 'table' then
          perfTestTestTime = perfTestData[screenShown].testTime[1] or DEFAULT_PERF_TEST_TIME
        else
          perfTestTestTime = perfTestData[screenShown].testTime or DEFAULT_PERF_TEST_TIME
        end
        perfTestSteps = perfTestData[screenShown].steps or DEFAULT_PERF_TEST_STEPS
        perfTestStepsCompleted = 0
        if type(perfTestData[screenShown].callbacks) == 'table' then
            -- update callback cache
            perfTestCallbackScreenCacheUpdate = perfTestData[screenShown].callbacks.CBUpdate

            -- callout to setup code
            if perfTestData[screenShown].callbacks.CBSetup then
                perfTestData[screenShown].callbacks.CBSetup(mapargs)
            end
        end
    end

    -- reset start time
    MeasuredResultReset()

    -- kick off test
    gre.send_event("test.update")
end

function CBScreenHidePre(mapargs) 
    local screenHidden = mapargs and mapargs.context_event_data and mapargs.context_event_data.name
    if type(perfTestData[screenHidden]) == 'table' then 
        if type(perfTestData[screenHidden].callbacks) == 'table' then
            -- callout to teardown code
            if perfTestData[screenHidden].callbacks.CBTeardown then
                perfTestData[screenHidden].callbacks.CBTeardown(mapargs)
            end
        end
    end
end

function CBScreenHidePost(mapargs) 
    local screenHidden = mapargs and mapargs.context_event_data and mapargs.context_event_data.name
    if type(perfTestData[screenHidden]) == 'table' then 
        if type(perfTestData[screenHidden].callbacks) == 'table' then
            -- callout to post-teardown code
            if perfTestData[screenHidden].callbacks.CBPostTeardown then
                perfTestData[screenHidden].callbacks.CBPostTeardown(mapargs)
            end
        end
    end
end


local CBTestUpdate = function ()
  gre.send_event('test.update')
end

local lastTime, started
function CBUpdate(mapargs)
  local elapsedTime = gre.mstime() - startTime
  
  if started == nil then
    local delay
    if elapsedTime <= 25 then
      delay = 2
    elseif elapsedTime < 500 then
      delay = 1
    else
      started = true
    end
    if lastTime == elapsedTime then
      gre.timer_set_timeout(CBTestUpdate, delay)
      return
    end
    lastTime = elapsedTime
  end
  
  if perfTestCallbackScreenCacheUpdate then
      perfTestCallbackScreenCacheUpdate(mapargs, elapsedTime)
  end

  local fps = gre.get_value("grd_fps")
  
  if fps ~= nil then
      perfResultSum = perfResultSum + fps
      perfResultSampleCount = perfResultSampleCount + 1
      perfResultMax = math.max(perfResultMax, fps)
      perfResultMin = math.min(perfResultMin, fps)
      ScreenPerfResultSum = ScreenPerfResultSum + fps
      ScreenPerfResultSampleCount = ScreenPerfResultSampleCount + 1
      ScreenPerfResultMax = math.max(ScreenPerfResultMax, fps)
      ScreenPerfResultMin = math.min(ScreenPerfResultMin, fps)
  end

  MeasureFramerate(elapsedTime)

  if elapsedTime < perfTestTestTime then
      gre.send_event("test.update")
  else
      gre.send_event("test.step_pre")
  end
  
end

function CBStepPre(mapargs)
  perfTestStepsCompleted = perfTestStepsCompleted + 1
  local screenActive = mapargs and mapargs.context_screen
  local lastStep = perfTestStepsCompleted
  if type(perfTestData[screenActive] == 'table') then
    if type(perfTestData[screenActive].callbacks) == 'table' then
      -- callout to pre-step code
      if perfTestData[screenActive].callbacks.CBStepPre then
        perfTestData[screenActive].callbacks.CBStepPre(mapargs, lastStep)
      end
    end
  end
  gre.send_event('test.step')
end

function CBStep(mapargs)
  local screenActive = mapargs and mapargs.context_screen
  local appActive = gre.get_value("test_name") or "unnamed_test"
  local lastStep = perfTestStepsCompleted
  
  ScreenMeasureFpsUpdate()
  if perfTestSteps > 1 then
    PerfResultSummary(appActive, screenActive, lastStep)
    PerfResultReset()
    
    MeasuredResultSummary(appActive, screenActive, lastStep)
    MeasuredResultReset()
    
    if perfTestStepsCompleted < perfTestSteps then
      local screenActive = mapargs and mapargs.context_screen
      if type(perfTestData[screenActive]) == 'table' then 
      
        if type(perfTestData[screenActive].testTime) == 'table' then
          perfTestTestTime = perfTestData[screenActive].testTime[lastStep + 1] or DEFAULT_PERF_TEST_TIME
        else
          perfTestTestTime = perfTestData[screenActive].testTime or DEFAULT_PERF_TEST_TIME
        end
        if type(perfTestData[screenActive].callbacks) == 'table' then
          --Callout to step code
          if perfTestData[screenActive].callbacks.CBStep then
            perfTestData[screenActive].callbacks.CBStep(mapargs, lastStep)
          end
        end
      end
      gre.send_event("test.update")
    else
      
      ScreenPerfResultSummary(appActive, screenActive)
      ScreenPerfResultReset()
      
      ScreenMeasuredResultSummary(appActive, screenActive)
      ScreenMeasuredResultReset()
      
      gre.send_event("test.completed")
    end
  else
    ScreenPerfResultSummary(appActive, screenActive)
    ScreenPerfResultReset()
    
    ScreenMeasuredResultSummary(appActive, screenActive)
    ScreenMeasuredResultReset()
    
    gre.send_event('test.completed')
  end
end

function sbperftest.RegisterPerfTest(name, callbacks, steps, duration)
    perfTestData[name] = {}
    perfTestData[name].callbacks = {}
    perfTestData[name].testTime = duration or DEFAULT_PERF_TEST_TIME
    perfTestData[name].steps = steps or DEFAULT_PERF_TEST_STEPS
    for i,v in pairs(callbacks) do
        perfTestData[name].callbacks[i] = v
    end
end

return sbperftest
