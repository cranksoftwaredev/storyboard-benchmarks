--[[
This test exercises and measures the resource management API in Lua.
Specifically we perform load/unload operations on fonts and images to 
ensure that changes we make to resource management is correct.

For each resource class (images/fonts) we have a list of resources
that we will force a dump from the resource cache and then a subsequent
reload.  This mimics the type of filesystem asset changes that a customer
might experience at runtime or a resource pre-load scenario.

--]]

maxImageIterations = 10
maxFontIterations = 10
testIteration = 1

imageList = {
 "images/RGBTest.jpg",
 "images/RGBTest.bmp",
 "images/RGBTest.png",
 "images/RGBTestAlpha.png",
 "images/RGBTestNoAlpha.png",
}

fontList = {
 "fonts/LiberationSerif-Regular.ttf",
 "fonts/Roboto-Medium.ttf",
 "fonts/VeraMono.ttf",
 "fonts/SourceHanSansTCRegular.ttf"
}

fontSizes = {
  {size = 9},
  {size = 22},
  {size = 35}
}

-- This font size can't be in the fontSizes list above we use it for a proxy
placeholderFontSize = 8;    

resourcePoolNames = {
  "image",
  "font"
}

testStartMS = 0
testEndMS = 0
metricList = { }

-- Increase the precision of mstime to 0.001 ms from 1 ms.
gre.mstime = function(v)
  return gre.ustime(v)/1000
end

local function resetTestCounters() 
  testIteration = 1
  testStartMS = 0
  testEndMS = 0
end

local function makeFontKey(prefix, fontName, fontSize) 
  return prefix .. fontName .. ":" .. tostring(fontSize)
end

local function dumpResultsImage(testTime) 
  for i=1,#imageList do
    local imgName = imageList[i]
    local avgTime = metricList[imgName] / maxImageIterations
    gre.log_perf_stat("ImageLoad", imgName, avgTime, "ms")
  end  
  
  gre.log_perf_stat("ImageLoad", "TotalTestTime", testEndMS-testStartMS, "ms")
end

local function dumpResultsFont(prefix)
  for i=1,#fontList do
    local fontName = fontList[i]
    for j=1,#fontSizes do
      local key = makeFontKey(prefix, fontName, fontSizes[j].size)
      local avgTime = metricList[key] / maxFontIterations
      gre.log_perf_stat("FontLoad", key:gsub(":", "_"), avgTime, "ms")
    end
  end
  
  gre.log_perf_stat("FontLoad", "TotalTestTime", testEndMS-testStartMS, "ms")
end

function cb_image_dumpAndLoad(mapargs) 
  if(testStartMS == 0) then
    testStartMS = gre.mstime()
  end
  
  -- Dump out any of the loaded resources
  for i=1,#imageList do
    gre.dump_resource("image",imageList[i])
  end
 
  -- Force a reload of the images
  for i=1,#imageList do
    local imgName = imageList[i]
    
    msstart = gre.mstime()
    gre.load_image(imgName)
    msend = gre.mstime()
    
    local loadTime = metricList[imgName]
    if(loadTime == nil) then
      loadTime = 0
    end
    metricList[imgName] = loadTime + (msend - msstart)
  end
  
  if(testIteration < maxImageIterations) then
    testIteration = testIteration + 1
    gre.send_event("dump_and_load")
  else
    testEndMS = gre.mstime()
    dumpResultsImage()
    resetTestCounters()
    gre.send_event("next_screen")
  end
end

local function RunFontTest(prefix, mapargs)
  if(testStartMS == 0) then
    testStartMS = gre.mstime()
  end
  
  --Dump out loaded fonts
  for i=1,#fontList do
    for j=1,#fontSizes do
      gre.dump_resource("font", fontList[i] .. ":" .. tostring(fontSizes[j].size))
    end
  end
  
  --Force reload of fonts
  for i=1,#fontList do
    local fontName = fontList[i]
    
    for j=1,#fontSizes do
      msstart = gre.mstime()
      gre.load_resource("font", fontName, fontSizes[j])
      msend = gre.mstime()
      
      local key = makeFontKey(prefix, fontName, fontSizes[j].size)
      local loadTime = metricList[key]
      if (loadTime == nil) then
        loadTime = 0
      end
      metricList[key] = loadTime + (msend - msstart)
    end
  end
  
  if (testIteration < maxFontIterations) then
    testIteration = testIteration + 1
    gre.send_event("dump_and_load_fonts")
  else
    testEndMS = gre.mstime()
    dumpResultsFont(prefix)
    resetTestCounters()
    gre.send_event("next_screen")
  end
end

function cb_font_dumpAndLoad(mapargs)
  RunFontTest("", mapargs)
end

-- This test differs from the font_dumpAndLoad because it preloads a font point
-- size that is not used 'first' and then runs a complete dump and load cycle of
-- all of the standard font point sizes used visually.
-- This test must run _after_ the font_dumpAndLoad
function cb_font_partialDumpAndLoad(mapargs)
  --Perform the pre-load of each font at a placeholder size.  
  --This font resource will not be dumped from the list
  if(testStartMS == 0) then
    for i=1,#fontList do
      gre.load_resource("font", fontList[i], placeholderFontSize)
    end
  end

  RunFontTest("Partial_", mapargs)
end


-- Walk through the resource pool and make sure that the thing 
-- mentioned here is not loaded in any capacity.  This has the
-- added benefit of exercising the resource walk call
function ensureResourceNotLoaded(thing)
  for i=1,#resourcePoolNames do
    local data = gre.walk_pool(resourcePoolNames[i])
    for k,v in pairs(data) do
      if(k:find(thing) ~= nil) then
        gre.dump_resource(resourcePoolNames[i], k)
      end
    end
  end
end

-- Measure the change in time to show an image that has been background loaded vs 
-- loaded on demand by the renderer.   We generate a sequence of events A vs B:
-- A) Test Start -> Async Load: 
--    Load Complete -> Snap Time, Show Control, Send End Event 
--    End Event -> Snap Time
-- B) Test Start -> Snap Time, Show Control, Send End Event
--    End Event -> Snap Time
local asyncId
--- @param gre#context mapargs
function cb_asyncLoadResources(mapargs) 
  local evName = mapargs.context_event
  local evData = mapargs.context_event_data
  
  
  if(evName == "start_async_test") then
    ensureResourceNotLoaded("BGLoad_RGBTest.png")
    ensureResourceNotLoaded("FGLoad_RGBTest.png")
    
    gre.load_resource("image","images/BGLoad_RGBTest.png", { background = 1 })    
    
    -- Set a timer if the async call isn't supported so we don't hang. 
    asyncId = gre.timer_set_timeout(function() 
     print("No Asynchronous Load Timer Firing")
     gre.send_event_data("stop_timing", "1s0 name", { name = "AsyncPNGLoad" })
    end, 3 * 1000)
    
  elseif(evName == "gre.resource_loaded") then
    gre.timer_clear_timeout(asyncId)

    gre.set_control_attrs("AsyncLayer.FG", { hidden = true })
    gre.set_control_attrs("AsyncLayer.BG", { hidden = false })
    gre.send_event_data("stop_timing", "1s0 name", { name = "AsyncPNGLoad" })
    testStartMS = gre.mstime()
  
  elseif(evName == "start_sync_test") then
    gre.set_control_attrs("AsyncLayer.FG", { hidden = false })
    gre.set_control_attrs("AsyncLayer.BG", { hidden = true })
    gre.send_event_data("stop_timing", "1s0 name", { name = "SyncPNGLoad" })
    testStartMS = gre.mstime()
    
  elseif(evName == "stop_timing") then
    testEndMS = gre.mstime()
    
    -- If this was an async load that failed, then the start
    -- time is going to be set to 0 (since it never really drew)
    -- so detect that scenario and generate a diagnostic message
    -- instead of a perf message
    local testName = evData.name
    if(testStartMS == 0) then
      print("No Asynchronous Load Notification Received")
    else
      gre.log_perf_stat(testName, "RedrawTime", testEndMS-testStartMS, "ms")
    end      
        
    --Decide if we are doing this again ...
    if(testName == "AsyncPNGLoad") then
      gre.send_event("start_sync_test")
    else 
      resetTestCounters()
      gre.send_event("next_screen")  
    end
  end
end
