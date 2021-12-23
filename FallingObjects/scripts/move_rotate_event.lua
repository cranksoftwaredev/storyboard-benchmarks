require 'sbperftest'
require 'movement'
require 'utility'

local screenSize
local screenKeys = {"screen_width", "screen_height"}
local clones = 1
local cloneTable = {}
local DEFAULT_PERF_TEST_TIME = 5000

local function CBIncreaseObjects(mapargs, step, ...)
  clones = (2 ^ step)
  for index = 1, #(...) do
    local v = (...)[index]
    local template = 'moving_' .. v
    local cloneData = {}
    for i = 1, clones - 1 do
      local cloneName = 'clone_' .. v .. i
      if cloneTable[index] == nil then
        cloneTable[index] = {}
      end
      if cloneTable[index][i] == nil then
        cloneData["hidden"] = true
        gre.clone_object(template, cloneName, v .. '_move_layer',cloneData)
        cloneTable[index][i] = v .. '_move_layer.' .. cloneName
      end
    end
  end
end

local function CBSpaceObjects(mapargs, ...)
  if screenSize == nil then
    screenSize = gre.env(screenKeys)
  end
  local data = {}
  local controlTable = {}
  local clonesIndexed = 0
  for index = 1 , #(...) do
    controlTable[index + clonesIndexed] = (...)[index] .. '_move_layer.moving_' .. (...)[index]
    for i = 1, clones - 1 do
      controlTable[index + clonesIndexed + i] = cloneTable[index][i]
      if i == clones - 1 then
        clonesIndexed = i * index
      end
    end
  end
  local controlWidth = math.ceil((screenSize[screenKeys[1]] / 1.5) / #controlTable)
  if controlWidth > screenSize[screenKeys[2]] then
    controlWidth = screenSize[screenKeys[2]]
  end
  local screenWidth = math.floor(screenSize[screenKeys[1]])
  local freeWidth = screenWidth - (#controlTable * controlWidth)
  local renderSize = math.floor(controlWidth * (math.sqrt(2) - 1))
  for i = 1, #controlTable do
    data[(controlTable[i]) .. '.grd_width'] = controlWidth
    data[(controlTable[i]) .. '.grd_height'] = controlWidth
    data[(controlTable[i]) .. '.grd_x'] = controlWidth * (i - 1) + (freeWidth / 2)
    data[(controlTable[i]) .. '.grd_y'] = 0
    data.render_width = renderSize
    data.render_height = renderSize
    data[controlTable[i] .. '.grd_hidden'] = false
  end
  gre.set_data(data)
end

local function CBUpdateData(mapargs, elapsedTime, testDuration, move, rotate, alpha, ...)
  if testDuration == nil then
    testDuration = DEFAULT_PERF_TEST_TIME
  end
  local data = {}
  local controlTable = {}
  local clonesIndexed = 0
  for index = 1 , #(...) do
    controlTable[index + clonesIndexed] = (...)[index] .. '_move_layer.moving_' .. (...)[index]
    for i = 1, clones - 1 do
      local cloneName = (...)[index] .. '_move_layer.clone_' .. (...)[index] .. i
      controlTable[index + clonesIndexed + i] = cloneTable[index][i]
      if i == clones - 1 then
        clonesIndexed = i * index
      end
    end
  end
  if (move) then
    local posTable = falling(elapsedTime, controlTable, mapargs, testDuration)
    
    for i = 1, #controlTable do
      if posTable[i] ~= nil then
        data[controlTable[i] .. '.grd_y'] = posTable[i]
      end
    end
  end
  if (rotate) then
    local angle = 20
    data.angle = angle
    data.txt_angle = 90
    for i = 1, #controlTable do
      data[controlTable[i] .. '.grd_hidden'] = false
    end
  end
  if (alpha) then
    local alpha = 127
    data.alpha = alpha
  end
  gre.set_data(data)
end

local function CBReset(mapargs, ...)
  if screenSize == nil then
    screenSize = gre.env(screenKeys)
  end
  CBSpaceObjects(mapargs, ...)
  reset()
end

local stepTable = {3}
for i = 1, 2 do
  stepTable[i + 1] = stepTable[i] - 1
end
local durationTable = {500}
for i = 1, 2 do
  durationTable[i + 1] = durationTable[i] * (i + 1)
end
local controlTables = {}
controlTables[1] = {'fill'}
controlTables[2] = {'rect'}
controlTables[3] = {'img'}
controlTables[4] = {'txt'}
controlTables[5] = {'arc'}
controlTables[6] = {'img', 'txt'}
controlTables[7] = {'fill', 'rect'}
controlTables[8] = {'fill', 'rect', 'img', 'txt'}

local alphaTable = {false, true}

--Fills
local fill_move_event = {}

function fill_move_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[1])
end
function fill_move_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[1], controlTables[1])
end
function fill_move_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[1])
  CBReset(mapargs, controlTables[1])
end
function fill_move_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[1])
end

sbperftest.RegisterPerfTest('fill_move_event',fill_move_event, stepTable[1], durationTable[1])

local fill_move_rotate_event = {}

function fill_move_rotate_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[1])
end
function fill_move_rotate_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[1], controlTables[1])
end
function fill_move_rotate_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[1])
  CBReset(mapargs, controlTables[1])
end
function fill_move_rotate_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[1])
end

sbperftest.RegisterPerfTest('fill_move_rotate_event',fill_move_rotate_event,stepTable[1], durationTable[1])

--Rects
local rect_move_event = {}

function rect_move_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[2])
end
function rect_move_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[1], controlTables[2])
end
function rect_move_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[2])
  CBReset(mapargs, controlTables[2])
end
function rect_move_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[2])
end

sbperftest.RegisterPerfTest('rect_move_event',rect_move_event,stepTable[1], durationTable[1])

local rect_move_rotate_event = {}

function rect_move_rotate_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[2])
end
function rect_move_rotate_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[1], controlTables[2])
end
function rect_move_rotate_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[2])
  CBReset(mapargs, controlTables[2])
end
function rect_move_rotate_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[2])
end

sbperftest.RegisterPerfTest('rect_move_rotate_event',rect_move_rotate_event,stepTable[1], durationTable[1])

--Fill and rect
local fill_rect_move_event = {}

function fill_rect_move_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[7])
end
function fill_rect_move_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[2], true, false, alphaTable[1], controlTables[7])
end
function fill_rect_move_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[7])
  CBReset(mapargs, controlTables[7])
end
function fill_rect_move_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[7])
end

sbperftest.RegisterPerfTest('fill_rect_move_event',fill_rect_move_event,stepTable[2], durationTable[2])

local fill_rect_move_rotate_event = {}

function fill_rect_move_rotate_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[7])
end
function fill_rect_move_rotate_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[2], true, true, alphaTable[1], controlTables[7])
end
function fill_rect_move_rotate_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[7])
  CBReset(mapargs, controlTables[7])
end
function fill_rect_move_rotate_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[7])
end

sbperftest.RegisterPerfTest('fill_rect_move_rotate_event',fill_rect_move_rotate_event,stepTable[2], durationTable[2])

--imgs
local img_move_event = {}

function img_move_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[3])
end
function img_move_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[1], controlTables[3])
end
function img_move_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[3])
  CBReset(mapargs, controlTables[3])
end
function img_move_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[3])
end

sbperftest.RegisterPerfTest('img_move_event',img_move_event,stepTable[1], durationTable[1])

local img_move_rotate_event = {}

function img_move_rotate_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[3])
end
function img_move_rotate_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[1], controlTables[3])
end
function img_move_rotate_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[3])
  CBReset(mapargs, controlTables[3])
end
function img_move_rotate_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[3])
end

sbperftest.RegisterPerfTest('img_move_rotate_event',img_move_rotate_event,stepTable[1], durationTable[1])

--txt
local txt_move_event = {}

function txt_move_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[4])
end
function txt_move_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[1], controlTables[4])
end
function txt_move_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[4])
  CBReset(mapargs, controlTables[4])
end
function txt_move_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[4])
end

sbperftest.RegisterPerfTest('txt_move_event',txt_move_event,stepTable[1], durationTable[1])

local txt_move_rotate_event = {}

function txt_move_rotate_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[4])
end
function txt_move_rotate_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[1], controlTables[4])
end
function txt_move_rotate_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[4])
  CBReset(mapargs, controlTables[4])
end
function txt_move_rotate_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[4])
end

sbperftest.RegisterPerfTest('txt_move_rotate_event',txt_move_rotate_event,stepTable[1], durationTable[1])

--img and txt
local img_txt_move_event = {}

function img_txt_move_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[6])
end
function img_txt_move_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[2], true, false, alphaTable[1], controlTables[6])
end
function img_txt_move_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[6])
  CBReset(mapargs, controlTables[6])
end
function img_txt_move_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[6])
end

sbperftest.RegisterPerfTest('img_txt_move_event',img_txt_move_event,stepTable[2], durationTable[2])

local img_txt_move_rotate_event = {}

function img_txt_move_rotate_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[6])
end
function img_txt_move_rotate_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[2], true, true, alphaTable[1], controlTables[6])
end
function img_txt_move_rotate_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[6])
  CBReset(mapargs, controlTables[6])
end
function img_txt_move_rotate_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[6])
end

sbperftest.RegisterPerfTest('img_txt_move_rotate_event',img_txt_move_rotate_event,stepTable[2], durationTable[2])

--Fill, rect, img and txt
local fill_rect_img_txt_move_event = {}

function fill_rect_img_txt_move_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[8])
end
function fill_rect_img_txt_move_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[3], true, false, alphaTable[1], controlTables[8])
end
function fill_rect_img_txt_move_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[8])
  CBReset(mapargs, controlTables[8])
end
function fill_rect_img_txt_move_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[8])
end

sbperftest.RegisterPerfTest('fill_rect_img_txt_move_event',fill_rect_img_txt_move_event,stepTable[3], durationTable[3])

local fill_rect_img_txt_move_rotate_event = {}

function fill_rect_img_txt_move_rotate_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[8])
end
function fill_rect_img_txt_move_rotate_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[3], true, true, alphaTable[1], controlTables[8])
end
function fill_rect_img_txt_move_rotate_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[8])
  CBReset(mapargs, controlTables[8])
end
function fill_rect_img_txt_move_rotate_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[8])
end

sbperftest.RegisterPerfTest('fill_rect_img_txt_move_rotate_event',fill_rect_img_txt_move_rotate_event,stepTable[3], durationTable[3])

--arcs
local arc_move_event = {}

function arc_move_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[5])
end
function arc_move_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[1], controlTables[5])
end
function arc_move_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[5])
  CBReset(mapargs, controlTables[5])
end
function arc_move_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[5])
end

sbperftest.RegisterPerfTest('arc_move_event',arc_move_event,stepTable[1], durationTable[1])

local arc_move_rotate_event = {}

function arc_move_rotate_event.CBSetup(mapargs)
  CBReset(mapargs, controlTables[5])
end
function arc_move_rotate_event.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[1], controlTables[5])
end
function arc_move_rotate_event.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[5])
  CBReset(mapargs, controlTables[5])
end
function arc_move_rotate_event.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[5])
end

sbperftest.RegisterPerfTest('arc_move_rotate_event',arc_move_rotate_event,stepTable[1], durationTable[1])
--Alpha

--Fills
local fill_move_event_alpha = {}

function fill_move_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[1])
end
function fill_move_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[2], controlTables[1])
end
function fill_move_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[1])
  CBReset(mapargs, controlTables[1])
end
function fill_move_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[1])
end

sbperftest.RegisterPerfTest('fill_move_event_alpha',fill_move_event_alpha,stepTable[1], durationTable[1])

local fill_move_rotate_event_alpha = {}

function fill_move_rotate_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[1])
end
function fill_move_rotate_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[2], controlTables[1])
end
function fill_move_rotate_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[1])
  CBReset(mapargs, controlTables[1])
end
function fill_move_rotate_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[1])
end

sbperftest.RegisterPerfTest('fill_move_rotate_event_alpha',fill_move_rotate_event_alpha,stepTable[1], durationTable[1])

--Rects
local rect_move_event_alpha = {}

function rect_move_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[2])
end
function rect_move_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[2], controlTables[2])
end
function rect_move_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[2])
  CBReset(mapargs, controlTables[2])
end
function rect_move_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[2])
end

sbperftest.RegisterPerfTest('rect_move_event_alpha',rect_move_event_alpha,stepTable[1], durationTable[1])

local rect_move_rotate_event_alpha = {}

function rect_move_rotate_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[2])
end
function rect_move_rotate_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[2], controlTables[2])
end
function rect_move_rotate_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[2])
  CBReset(mapargs, controlTables[2])
end
function rect_move_rotate_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[2])
end

sbperftest.RegisterPerfTest('rect_move_rotate_event_alpha',rect_move_rotate_event_alpha,stepTable[1], durationTable[1])

--Fill and rect
local fill_rect_move_event_alpha = {}

function fill_rect_move_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[7])
end
function fill_rect_move_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[2], true, false, alphaTable[2], controlTables[7])
end
function fill_rect_move_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[7])
  CBReset(mapargs, controlTables[7])
end
function fill_rect_move_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[7])
end

sbperftest.RegisterPerfTest('fill_rect_move_event_alpha',fill_rect_move_event_alpha,stepTable[2], durationTable[2])

local fill_rect_move_rotate_event_alpha = {}

function fill_rect_move_rotate_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[7])
end
function fill_rect_move_rotate_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[2], true, true, alphaTable[2], controlTables[7])
end
function fill_rect_move_rotate_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[7])
  CBReset(mapargs, controlTables[7])
end
function fill_rect_move_rotate_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[7])
end

sbperftest.RegisterPerfTest('fill_rect_move_rotate_event_alpha',fill_rect_move_rotate_event_alpha,stepTable[2], durationTable[2])

--imgs
local img_move_event_alpha = {}

function img_move_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[3])
end
function img_move_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[2], controlTables[3])
end
function img_move_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[3])
  CBReset(mapargs, controlTables[3])
end
function img_move_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[3])
end

sbperftest.RegisterPerfTest('img_move_event_alpha',img_move_event_alpha,stepTable[1], durationTable[1])

local img_move_rotate_event_alpha = {}

function img_move_rotate_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[3])
end
function img_move_rotate_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[2], controlTables[3])
end
function img_move_rotate_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[3])
  CBReset(mapargs, controlTables[3])
end
function img_move_rotate_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[3])
end

sbperftest.RegisterPerfTest('img_move_rotate_event_alpha',img_move_rotate_event_alpha,stepTable[1], durationTable[1])

local txt_move_event_alpha = {}

function txt_move_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[4])
end
function txt_move_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[2], controlTables[4])
end
function txt_move_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[4])
  CBReset(mapargs, controlTables[4])
end
function txt_move_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[4])
end

sbperftest.RegisterPerfTest('txt_move_event_alpha',txt_move_event_alpha,stepTable[1], durationTable[1])

local txt_move_rotate_event_alpha = {}

function txt_move_rotate_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[4])
end
function txt_move_rotate_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[2], controlTables[4])
end
function txt_move_rotate_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[4])
  CBReset(mapargs, controlTables[4])
end
function txt_move_rotate_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[4])
end

sbperftest.RegisterPerfTest('txt_move_rotate_event_alpha',txt_move_rotate_event_alpha,stepTable[1], durationTable[1])

--img and txt
local img_txt_move_event_alpha = {}

function img_txt_move_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[6])
end
function img_txt_move_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[2], true, false, alphaTable[2], controlTables[6])
end
function img_txt_move_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[6])
  CBReset(mapargs, controlTables[6])
end
function img_txt_move_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[6])
end

sbperftest.RegisterPerfTest('img_txt_move_event_alpha',img_txt_move_event_alpha,stepTable[2], durationTable[2])

local img_txt_move_rotate_event_alpha = {}

function img_txt_move_rotate_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[6])
end
function img_txt_move_rotate_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[2], true, true, alphaTable[2], controlTables[6])
end
function img_txt_move_rotate_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[6])
  CBReset(mapargs, controlTables[6])
end
function img_txt_move_rotate_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[6])
end

sbperftest.RegisterPerfTest('img_txt_move_rotate_event_alpha',img_txt_move_rotate_event_alpha,stepTable[2], durationTable[2])

--Fill, rect, img and txt
local fill_rect_img_txt_move_event_alpha = {}

function fill_rect_img_txt_move_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[8])
end
function fill_rect_img_txt_move_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[3], true, false, alphaTable[2], controlTables[8])
end
function fill_rect_img_txt_move_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[8])
  CBReset(mapargs, controlTables[8])
end
function fill_rect_img_txt_move_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[8])
end

sbperftest.RegisterPerfTest('fill_rect_img_txt_move_event_alpha',fill_rect_img_txt_move_event_alpha,stepTable[3], durationTable[3])

local fill_rect_img_txt_move_rotate_event_alpha = {}

function fill_rect_img_txt_move_rotate_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[8])
end
function fill_rect_img_txt_move_rotate_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[3], true, true, alphaTable[2], controlTables[8])
end
function fill_rect_img_txt_move_rotate_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[8])
  CBReset(mapargs, controlTables[8])
end
function fill_rect_img_txt_move_rotate_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[8])
end

sbperftest.RegisterPerfTest('fill_rect_img_txt_move_rotate_event_alpha',fill_rect_img_txt_move_rotate_event_alpha,stepTable[3], durationTable[3])

local arc_move_event_alpha = {}

function arc_move_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[5])
end
function arc_move_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, false, alphaTable[2], controlTables[5])
end
function arc_move_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[5])
  CBReset(mapargs, controlTables[5])
end
function arc_move_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[5])
end

sbperftest.RegisterPerfTest('arc_move_event_alpha',arc_move_event_alpha,stepTable[1], durationTable[1])

local arc_move_rotate_event_alpha = {}

function arc_move_rotate_event_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[5])
end
function arc_move_rotate_event_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, elapsedTime, durationTable[1], true, true, alphaTable[2], controlTables[5])
end
function arc_move_rotate_event_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[5])
  CBReset(mapargs, controlTables[5])
end
function arc_move_rotate_event_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[5])
end

sbperftest.RegisterPerfTest('arc_move_rotate_event_alpha',arc_move_rotate_event_alpha,stepTable[1], durationTable[1])