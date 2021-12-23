
local numFrames = 0
local iters = 0
local TEST_DURATION = 4000 -- 4 seconds
local function TestMakePointerData(x, y)
  local fmt = "4u1 button 4u1 timestamp 2u1 subtype 2s1 x 2s1 y 2s1 z 2s1 id 2s1 state"

  local data = {}
  data.button = 0
  data.timestamp = 0
  data.subtype = 0
  data.x = x
  data.y = y
  data.z = 0
  data.id = 0
  data.state = 0

  return { data=data, fmt=fmt }
end

function testComplete()
  gre.quit()
end
-- Local routine for pausing, this can only be used in a non-main thread
local function mspause(ms)
  if(ms <= 1) then
    return
  end

  local msend = gre.mstime() + ms
  while(gre.mstime() < msend) do
  --Nothing to do .. just spin
  end
end

--- @param gre#context mapargs
function CBStartTest(mapargs)
  gre.send_event("gre.swcursor.enable")
  moveCursor()
end

local x = 21
local y = 0
local delta = 15
local xU = 780
local xL = 20
local yU = 25
function moveCursor()
  local now = gre.mstime()
  numFrames = numFrames + 1
  if (numFrames == 1) then
    firstFrameTime = now
  elseif ((now - firstFrameTime) > TEST_DURATION) then
    local fps = ((numFrames-1) * 1000) / (now - firstFrameTime)
    --    print("FPS: " .. tostring(math.floor(fps)))
    gre.log_perf_stat("SWCursorBenchmark", "Framerate", math.floor(fps), "fps")
    testComplete()
    return
  end

  --Movement logic
  if(xL < x and x < xU) then
    x = x + delta
  elseif(y < yU) then
    y = y + 1
  else
    delta = delta * -1
    yU = yU + 5
    if(yU > 475) then
      x = 21
      y = 0
      yU = 25
    end
    x = x + delta
  end

  ev = TestMakePointerData(x, y)
  --    print("Motion ... ", tostring(x), tostring(y))
  gre.send_event_data("gre.motion", ev.fmt, ev.data)
  --    mspause(1000/60)
  gre.send_event("next_move")

end
