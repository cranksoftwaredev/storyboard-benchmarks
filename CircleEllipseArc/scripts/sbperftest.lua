--
-- sbperftest.lua
--
-- The 'sbperftest' lua module is a lua module that is intended to be included
-- in all performance test scenarios. This module includes common code that
-- is used to measure various performance metrics.
--
-- The master version of this file lives in SVN at:
-- product_samples/benchmarks/perftest_example/scripts/perftest.lua
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
-- test.completed -> gra.sendevent: gre.quit OR gra.screen: [next_screen]
--   Screen of last test should -> gra.lua: CBAllTestsComplete()
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
local APP_RELATIVE = true
local DEFAULT_PERF_TEST_TIME = 3000
local startTime = gre.mstime()

local measureSampleDuration = 500;
local measureLastSampleTime = 0;
local measureSampleFrameAccum = 0;

local measureSampleCount = 0;
local measureFpsSum = 0
local measureFpsMin = math.huge
local measureFpsMax = 0

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

local MeasuredResultSummary = function (appName, testName)
  testName = testName .. '_ups';
  local fpsMin = measureFpsMin
  local fpsMax = measureFpsMax
  local fpsAvg = measureFpsSum / measureSampleCount
  if measureSampleCount > 0 then
    gre.log_perf_stat(appName, testName, fpsAvg, "ups")
    gre.log(gre.LOG_ALWAYS, 
      string.format("PERF3: %s,%s: %0.5f/%0.5f/%0.5f (%d samples)", 
        appName, testName, fpsMin, fpsMax, fpsAvg, measureSampleCount))
  end
end

local MeasuredResultReset = function ()
  measureLastSampleTime = 0;
  measureSampleFrameAccum = 0;

  measureSampleCount = 0
  measureFpsSum = 0
  measureFpsMin = math.huge
  measureFpsMax = 0
end


sbperftest = {}

local perfTestData = {}
local perfTestTestTime = DEFAULT_PERF_TEST_TIME
local perfTestCallbackScreenCacheUpdate = nil

local perfResultSampleCount = 0
local perfResultSum = 0
local perfResultMin = math.huge
local perfResultMax = 0

local firstScreen = ''
local firstScreenSet = false
local SBLoopCount = 0
local SBLoopExecution = os.getenv('SB_LOOP_EXECUTION')

local PerfResultSummary = function (appName, testName)
  testName = testName .. '_fps';
  local fpsMin = perfResultMin
  local fpsMax = perfResultMax
  local fpsAvg = perfResultSum / perfResultSampleCount
  if perfResultSampleCount > 0 then
    gre.log_perf_stat(appName, testName, fpsAvg, "fps")
    gre.log(gre.LOG_ALWAYS,
      string.format("PERF2: %s,%s: %0.5f/%0.5f/%0.5f (%d samples)",
        appName, testName, fpsMin, fpsMax, fpsAvg, perfResultSampleCount))
  end
end

local PerfResultReset = function ()
  perfResultSampleCount = 0
  perfResultSum = 0
  perfResultMin = math.huge
  perfResultMax = 0
end

function CBInit(mapargs)
  gre.log(gre.LOG_INFO, 'Initializing test.')
  if SBLoopExecution == nil then
    SBLoopExecution = 1
  else
    SBLoopExecution = tonumber(SBLoopExecution)
    if (SBLoopExecution < 1) then
      gre.log(gre.LOG_ERROR, 'Value of SB_LOOP_EXECUTION must be ast least 1.')
      gre.send_event("gre.quit")
    end
  end
  gre.log(gre.LOG_ALWAYS, 'Running with SB_LOOP_EXECUTION=' .. SBLoopExecution .. '.')
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
  if not firstScreenSet then
    gre.set_value('firstScreen', screenShown)
    firstScreenSet = true
  end
  if type(perfTestData[screenShown]) == 'table' then

    -- update test time
    perfTestTestTime = perfTestData[screenShown].testTime or DEFAULT_PERF_TEST_TIME

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
  startTime = gre.mstime()

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

function CBUpdate(mapargs)
  local elapsedTime = gre.mstime() - startTime

  if perfTestCallbackScreenCacheUpdate then
    perfTestCallbackScreenCacheUpdate(mapargs, elapsedTime)
  end

  fps = gre.get_value("grd_fps")
  if fps then
    perfResultSum = perfResultSum + fps
    perfResultSampleCount = perfResultSampleCount + 1
    perfResultMax = math.max(perfResultMax, fps)
    perfResultMin = math.min(perfResultMin, fps)
  end

  MeasureFramerate(elapsedTime)

  if elapsedTime < perfTestTestTime then
    gre.send_event("test.update")
  else
    local screenActive = mapargs and mapargs.context_screen
    local appActive = gre.get_value("test_name") or "unnamed_test"

    PerfResultSummary(appActive, screenActive)
    PerfResultReset()

    MeasuredResultSummary(appActive, screenActive)
    MeasuredResultReset()

    gre.send_event("test.completed")
  end
end

function CBAllTestsComplete(mapargs)
  SBLoopCount = SBLoopCount + 1
  gre.log(gre.LOG_ALWAYS, 'Finshed executing loop ' .. SBLoopCount .. ' of ' .. SBLoopExecution .. '.')
  gre.log(gre.LOG_ALWAYS, 'POLL_MEMORY_LOOP_MARKER: '..
    string.format("%d,%d", SBLoopCount, gre.mstime(APP_RELATIVE)))
  if SBLoopExecution < 0 then
    gre.send_event("go_to_first_screen")
  elseif SBLoopCount >= SBLoopExecution then
    gre.send_event("gre.quit")
  else
    gre.send_event("go_to_first_screen")
  end
end

function sbperftest.RegisterPerfTest(name, callbacks, duration)
  perfTestData[name] = {}
  perfTestData[name].callbacks = {}
  perfTestData[name].testTime = duration or DEFAULT_PERF_TEST_TIME

  for i,v in pairs(callbacks) do
    perfTestData[name].callbacks[i] = v
  end
end

return sbperftest
