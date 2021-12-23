local VIEWPORT_SIZE = 2000
local SCREEN_SIZE = 500
local WRAP_AREA_BOUNDS = (VIEWPORT_SIZE * 2) - SCREEN_SIZE
local VIEWPORT_AREA_BOUNDS = -VIEWPORT_SIZE + SCREEN_SIZE
local numFrames = 0
local increment = -5
local curOffset = 0
local startTime = 0

local curLayer = ""
local curScreen = 1
local curTest = 1

-- layer wrap offset tests
local testState = {
  {next = "Screen1", layer = "HorizontalWrapLayer", tests = {{name = "CBRunWrapAreaWidth", start = VIEWPORT_SIZE, label = "Wrap Area"}, {name = "CBRunViewportAreaWidth", start = 0, label = "Viewport Area"}}, label = "No Wrap"},
  {next = "Screen2", layer = "HorizontalWrapLayer", tests = {{name = "CBRunWrapAreaWidth", start = VIEWPORT_SIZE, label = "Wrap Area"}, {name = "CBRunViewportAreaWidth", start = 0, label = "Viewport Area"}}, label = "Horizontal Wrap"},
  {next = "Screen3", layer = "VerticalWrapLayer", tests = {{name = "CBRunWrapAreaHeight", start = VIEWPORT_SIZE, label = "Wrap Area"}, {name = "CBRunViewportAreaHeight", start = 0, label = "Viewport Area"}}, label = "Vertical Wrap"},
  {next = "Screen4", layer = "HorizontalWrapLayer", tests = {{name = "CBRunDualWrapHorizontal", start = VIEWPORT_SIZE, label = "Wrap Area"}}, label = "Dual Wrap Horizontal"},
  {next = nil, layer = "VerticalWrapLayer", tests = {{name = "CBRunDualWrapVertical", start = VIEWPORT_SIZE, label = "Wrap Area"}}, label = "Dual Wrap Vertical"}
}

---
-- @param gre#context mapargs
function CBStartTest(mapargs)
  local state = testState[curScreen]
  local test = state.tests[curTest]
  curLayer = string.format("%s.%s", mapargs.context_screen, state.layer)
  curOffset = test.start
  numFrames = 0
  startTime = gre.mstime()
  gre.set_value("currentTest", test.name)
  gre.send_event("next_frame")
end

---
-- @param gre#context mapargs
function CBEndTest(mapargs)
  local now = gre.mstime()
  local state = testState[curScreen]
  local test = state.tests[curTest]
  
  -- log stats
  local fps = (numFrames * 1000) / (now - startTime)
  gre.log_perf_stat(state.label, test.label, fps, "fps")
  
  curTest = curTest + 1
  if (curTest > #state.tests) then
    if (state.next == nil) then
      gre.quit()
      return
    end
    
    gre.set_value("currentScreen", state.next)
    gre.send_event("screen_change")
    curTest = 1
    curScreen = curScreen + 1
  else
    gre.send_event("next_test")  
  end
end

---
-- @param gre#context mapargs
function CBRunViewportAreaWidth(mapargs)
  if (curOffset <= VIEWPORT_AREA_BOUNDS) then
    CBEndTest(mapargs)
    return
  end
  
  curOffset = curOffset + increment
  numFrames = numFrames + 1
  gre.set_layer_attrs(curLayer, {xoffset = curOffset})
  gre.send_event("next_frame")
end

---
-- @param gre#context mapargs
function CBRunViewportAreaHeight(mapargs)
  if (curOffset <= VIEWPORT_AREA_BOUNDS) then
    CBEndTest(mapargs)
    return
  end
  
  curOffset = curOffset + increment
  numFrames = numFrames + 1
  gre.set_layer_attrs(curLayer, {yoffset = curOffset})
  gre.send_event("next_frame")
end

---
-- @param gre#context mapargs
function CBRunWrapAreaWidth(mapargs)
  if (curOffset <= -WRAP_AREA_BOUNDS) then
    CBEndTest(mapargs)
    return
  end
  
  curOffset = curOffset + increment
  if (curOffset < 0 and curOffset > VIEWPORT_AREA_BOUNDS) then
    curOffset = VIEWPORT_AREA_BOUNDS
  end
  numFrames = numFrames + 1
  gre.set_layer_attrs(curLayer, {xoffset = curOffset})
  gre.send_event("next_frame")
end

---
-- @param gre#context mapargs
function CBRunWrapAreaHeight(mapargs)
  if (curOffset <= -WRAP_AREA_BOUNDS) then
    CBEndTest(mapargs)
    return
  end
  
  curOffset = curOffset + increment
  if (curOffset < 0 and curOffset > VIEWPORT_AREA_BOUNDS) then
    curOffset = VIEWPORT_AREA_BOUNDS
  end
  numFrames = numFrames + 1
  gre.set_layer_attrs(curLayer, {yoffset = curOffset})
  gre.send_event("next_frame")
end

---
-- @param gre#context mapargs
function CBRunDualWrapHorizontal(mapargs)
  if (curOffset <= -WRAP_AREA_BOUNDS) then
    CBEndTest(mapargs)
    return
  end
  
  curOffset = curOffset + increment
  numFrames = numFrames + 1
  gre.set_layer_attrs(curLayer, {xoffset = curOffset, yoffset = (SCREEN_SIZE / 2)})
  gre.send_event("next_frame")
end

---
-- @param gre#context mapargs
function CBRunDualWrapVertical(mapargs)
  if (curOffset <= -WRAP_AREA_BOUNDS) then
    CBEndTest(mapargs)
    return
  end
  
  curOffset = curOffset + increment
  numFrames = numFrames + 1
  gre.set_layer_attrs(curLayer, {yoffset = curOffset, xoffset = (SCREEN_SIZE / 2)})
  gre.send_event("next_frame")
end