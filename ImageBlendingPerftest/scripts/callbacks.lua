local TICK_COUNT = 0
local FPS_SAMPLE_FRAME = 200
local homeScreenShow_data = {}

local ANIMATION_TICKS = 645
local ANIMATION_LOOP = 1
local ANIMATION_LOOP_COUNT = 1

-- Support gre.perflog for older engines
if not gre.log_perf_stat then
    gre.log_perf_stat = gre.perflog
end

local startTime = gre.mstime()
local function getTimer()
  return  math.floor(gre.mstime() - startTime)
end

local perfLogMSDelay = 0
local sampleFPS = 0;
local sampleDuration = 1000; --frames are incremented on each render, sampleDuration says how many milliseconds to average that data over before displaying
local lastSampledTime = 0;
local sampleFrames = 0;

local function calculateFramerate()
  local currentMSTime = getTimer()
  local testCategory
  local testName
  local diff = currentMSTime - lastSampledTime;
  local rawFPS = FPS_SAMPLE_FRAME/(diff/1000)
  sampleFPS = math.floor(rawFPS*100)/100 --format as XX.XX
  testName = 'loop_' .. ANIMATION_LOOP_COUNT .. '__tick_' .. TICK_COUNT
  --print('Last sampled:' .. lastSampledTime)
  --print('currentTime:' .. currentMSTime)
  --print('diff:' .. diff)
  --print('TICK_COUNT' .. TICK_COUNT)
  gre.log_perf_stat('homeScreenShow', testName, sampleFPS, "fps")
  lastSampledTime = currentMSTime;
end

local function animate(kwargs, data)
  local path = kwargs.path
  local valueMap = kwargs.valueMap
  if valueMap then
    if valueMap[TICK_COUNT] then
      data[path] = valueMap[TICK_COUNT]
    end
    return
  else
    local tickStart = kwargs.tickStart or 0
    local tickOffset = kwargs.tickOffset
    local tickEnd = kwargs.tickEnd or (tickStart + tickOffset)
    local valueStart = kwargs.valueStart or 0
    local valueOffset = kwargs.valueOffset
    local valueEnd = kwargs.valueEnd or (valueStart + valueOffset)

    tickOffset = tickEnd - tickStart
    valueOffset = valueEnd - valueStart

    local tickDelta = valueOffset/tickOffset

    if TICK_COUNT == 0 then
      data[path] = valueStart
    elseif TICK_COUNT >= tickStart and TICK_COUNT < tickEnd then
      data[path] = data[path] + tickDelta
    end
  end
end

local function animateMap(kwargs, data)
  local path = kwargs.path

end

local alpha_changes = {
  {path='background.animExtra1.alpha', tickStart=200, tickOffset=250, valueOffset=150},
  {path='background.animExtra2.alpha', tickStart=241, tickOffset=250, valueOffset=150},
  {path='background.animExtra3.alpha', tickStart=331, tickOffset=250, valueOffset=150},
  {path='background.animExtra4.alpha', tickStart=395, tickOffset=250, valueOffset=254},
  {path='background.backgroundAnimated.alpha', tickOffset=500, valueStart=254, valueEnd=0},
  {path='background.backgroundOverlay.alpha', tickOffset=200, valueEnd=254},
  {path='homeAllCookModes.bake.unselected.alpha', tickStart=296, tickOffset=250, valueEnd=254},
  {path='homeAllCookModes.broil.unselected.alpha', tickStart=346, tickOffset=250, valueEnd=254},
  {path='homeAllCookModes.convBake.unselected.alpha', tickStart=364, tickOffset=250, valueEnd=254},
  {path='homeAllCookModes.energy.unselected.alpha', tickStart=395, tickOffset=250, valueEnd=254},
  {path='homeAllCookModes.roast.unselected.alpha', tickStart=395, tickOffset=250, valueEnd=254},
  {path='homeAllCookModes.roast.selfClean.alpha', tickStart=296, tickOffset=250, valueEnd=254},
  {path='homeAllCookModes.smartCook.selfClean.alpha', tickStart=232, tickOffset=250, valueEnd=254},
  {path='homeAllCookModes.warm.selfClean.alpha', tickStart=346, tickOffset=250, valueEnd=254},
  {path='homeSelection.centerCircleLines_group.botCircle.alpha', tickStart=207, tickOffset=200, valueEnd=217},
  {path='homeSelection.centerCircleLines_group.leftInnerFade.alpha', tickOffset=300, valueEnd=82},
  {path='homeSelection.centerCircleLines_group.midCircle.alpha', tickStart=153, tickOffset=200, valueEnd=191},
  {path='homeSelection.centerCircleLines_group.outerCircleLeft.alpha', tickStart=58, tickOffset=300, valueEnd=128},
  {path='homeSelection.centerCircleLines_group.outerCircleRight.alpha', tickStart=58, tickOffset=300, valueEnd=128},
  {path='homeSelection.centerCircleLines_group.rightInnerFade.alpha', tickOffset=300, valueEnd=82},
  {path='homeSelection.centerCircleLines_group.topCircles.alpha', tickStart=89, tickOffset=200, valueEnd=128},
  {path='homeSelection.centerText_group.cookMode.alpha', tickStart=103, tickOffset=250, valueEnd=254},
  {path='homeSelection.centerText_group.quickStartMode.alpha', tickStart=64, tickOffset=250, valueEnd=254},
  {path='homeSelection.centerText_group.setup.alpha', tickStart=157, tickOffset=300, valueEnd=254},
  {path='homeSelection.innerFade.alpha', tickStart=203, tickOffset=410, valueEnd=254},
  {path='homeSliderLeft.selfClean.background.alpha', tickStart=232, tickOffset=250, valueEnd=254},
  {path='homeSliderLeft.selfClean.icon.alpha', tickStart=282, tickOffset=250, valueEnd=254},
  {path='homeSliderLeft.warm.background.alpha', tickStart=296, tickOffset=250, valueEnd=254},
  {path='homeSliderLeft.warm.icon.alpha', tickStart=346, tickOffset=250, valueEnd=254},
  {path='homeSliderMid.smartCook.alpha', tickStart=203, tickOffset=300, valueEnd=128},
  {path='homeSliderRight.bake.background.alpha', tickStart=232, tickOffset=250, valueEnd=254},
  {path='homeSliderRight.bake.icon.alpha', tickStart=282, tickOffset=250, valueEnd=254},
  {path='homeSliderRight.broil.background.alpha', tickStart=296, tickOffset=250, valueEnd=254},
  {path='homeSliderRight.broil.icon.alpha', tickStart=346, tickOffset=250, valueEnd=254},
  {path='voiceActivationHeader.dotRightOuter.alpha', tickStart=58, tickOffset=300, valueEnd=254},
  {path='voiceActivationHeader.dotRightInner.alpha', tickOffset=300, valueEnd=254},
  {path='voiceActivationHeader.dotLeftOuter.alpha', tickStart=58, tickOffset=300, valueEnd=254},
  {path='voiceActivationHeader.dotLeftInner.alpha', tickOffset=300, valueEnd=254},
  {path='voiceActivationHeader.callToAction.alpha', tickStart=206, tickOffset=300, valueEnd=254},
}

local other_changes = {
  {path='homeSelection.centerCircleLines_group.leftInnerFade.grd_x', tickOffset=250, valueStart=90, valueEnd=65},
  {path='homeSelection.centerCircleLines_group.outerCircleLeft.grd_x', tickStart=58, tickOffset=300, valueStart=25, valueEnd=0},
  {path='homeSelection.centerCircleLines_group.outerCircleRight.grd_x', tickStart=58, tickOffset=300, valueStart=339, valueEnd=364},
  {path='homeSelection.centerCircleLines_group.rightInnerFade.grd_x', tickOffset=250, valueStart=301, valueEnd=326},
  {path='homeSelection.centerText_group.cookMode.grd_y', tickStart=103, tickOffset=250, valueStart=25, valueEnd=0},
  {path='homeSelection.centerText_group.quickStartMode.grd_y', tickStart=64, tickOffset=250, valueStart=90, valueEnd=78},
  {path='homeSelection.centerText_group.setup.grd_y', tickStart=157, tickOffset=300, valueStart=482, valueEnd=507},
  {path='homeSliderLeft.selfClean.grd_x', tickStart=232, tickOffset=300, valueStart=425, valueEnd=400},
  {path='homeSliderLeft.warm.grd_x', tickStart=296, tickOffset=300, valueStart=225, valueEnd=200},
  {path='homeSliderMid.smartCook.height', tickStart=203, tickOffset=300, valueStart=125, valueEnd=221},
  {path='homeSliderRight.bake.grd_x', tickStart=203, tickOffset=300, valueStart=180, valueEnd=205},
  {path='homeSliderRight.broil.grd_x', tickStart=296, tickOffset=300, valueStart=380, valueEnd=405},
  {path='voiceActivationHeader.dotRightOuter.grd_x', tickStart=58, tickOffset=396, valueStart=818, valueEnd=865},
  {path='voiceActivationHeader.dotRightInner.grd_x', tickOffset=396, valueStart=808, valueEnd=848},
  {path='voiceActivationHeader.dotLeftOuter.grd_x', tickStart=58, tickOffset=396, valueStart=442, valueEnd=399},
  {path='voiceActivationHeader.dotLeftInner.grd_x', tickOffset=396, valueStart=452, valueEnd=412},
  {path='homeSelection.centerCircleLines_group.outerCircle.alpha', valueMap={[0]=0, [357]=128}},
  {path='background.backgroundAnimated.grd_hidden', valueMap={[0]=0, [500]=1}},
  {path='homeAllCookModes.bake.selected.grd_hidden', valueMap={[0]=1, [296]=0}},
  {path='homeAllCookModes.bake.unselected.grd_hidden', valueMap={[0]=1, [296]=0}},
  {path='homeAllCookModes.broil.selected.grd_hidden', valueMap={[0]=0, [346]=1}},
  {path='homeAllCookModes.broil.unselected.grd_hidden', valueMap={[0]=1, [346]=0}},
  {path='homeAllCookModes.convBake.selected.grd_hidden', valueMap={[0]=1, [364]=0}},
  {path='homeAllCookModes.convBake.unselected.grd_hidden', valueMap={[0]=1, [364]=0}},
  {path='homeAllCookModes.energy.selected.grd_hidden', valueMap={[0]=1, [395]=0}},
  {path='homeAllCookModes.energy.unselected.grd_hidden', valueMap={[0]=1, [395]=0}},
  {path='homeAllCookModes.roast.selected.grd_hidden', valueMap={[0]=1, [395]=0}},
  {path='homeAllCookModes.roast.unselected.grd_hidden', valueMap={[0]=1, [395]=0}},
  {path='homeAllCookModes.selfClean.selected.grd_hidden', valueMap={[0]=1, [296]=0}},
  {path='homeAllCookModes.selfClean.unselected.grd_hidden', valueMap={[0]=1, [296]=0}},
  {path='homeAllCookModes.smartCook.selected.grd_hidden', valueMap={[0]=1, [232]=0}},
  {path='homeAllCookModes.smartCook.unselected.grd_hidden', valueMap={[0]=1, [483]=0}},
  {path='homeAllCookModes.warm.selected.grd_hidden', valueMap={[0]=1, [346]=0}},
  {path='homeAllCookModes.warm.unselected.grd_hidden', valueMap={[0]=1, [346]=0}},
  {path='homeScreen.fakeBackgroundOverlay.grd_hidden', valueMap={[0]=1}},
  {path='homeScreen.homeAllCookModes.grd_hidden', valueMap={[0]=0}},
  {path='homeScreen.homeSelection.grd_hidden', valueMap={[0]=0}},
  {path='homeScreen.homeSelectionSlider.grd_hidden', valueMap={[0]=1, [645]=0}},
  {path='homeScreen.homeSliderLeft.grd_hidden', valueMap={[0]=0}},
  {path='homeScreen.homeSliderMid.grd_hidden', valueMap={[0]=0}},
  {path='homeScreen.homeSliderRight.grd_hidden', valueMap={[0]=0}},
  {path='homeSelection.centerCircleLines_group.outerCircle.grd_hidden', valueMap={[0]=1, [357]=0}},
  {path='homeSelection.centerCircleLines_group.outerCircleLeft.grd_hidden', valueMap={[0]=0, [357]=1}},
  {path='homeSelection.centerCircleLines_group.outerCircleRight.grd_hidden', valueMap={[0]=0, [357]=1}},
  {path='homeSelection.centerCircleOverlay.grd_hidden', valueMap={[0]=1, [500]=0}},
  {path='homeSelection.sliderFadeLeft.grd_hidden', valueMap={[0]=1, [500]=0}},
  {path='homeSelection.sliderFadeRight.grd_hidden', valueMap={[0]=1, [500]=0}},
  {path='homeScreen.voiceActivationHeader.grd_hidden', valueMap={[0]=0}},
}

local function resetAnimation()
  TICK_COUNT = 0
  homeScreenShow_data = {}
end

function CBLoop()
  -- Event driven version of APP_homeScreenShow animation
  for i, alpha_change in ipairs(alpha_changes) do
    animate(alpha_change, homeScreenShow_data)
  end

--  for k,v in pairs(data) do
--    print(TICK_COUNT, k, v)
--  end
  gre.set_data(homeScreenShow_data)
  
  if TICK_COUNT > 0 and TICK_COUNT % FPS_SAMPLE_FRAME == 0 then
      calculateFramerate()
  end

  TICK_COUNT = TICK_COUNT + 1
  if TICK_COUNT <= ANIMATION_TICKS then
    gre.send_event('timer.tick')
  else

    if ANIMATION_LOOP_COUNT <= ANIMATION_LOOP-1 then
      if ANIMATION_LOOP > 1 then
        print('Finished executing loop ' .. ANIMATION_LOOP_COUNT+1 .. ' of ' .. ANIMATION_LOOP)
      end
      resetAnimation()
      ANIMATION_LOOP_COUNT = ANIMATION_LOOP_COUNT + 1
      gre.send_event('timer.tick')
    else
      gre.send_event('gre.quit')
    end
  end
end
