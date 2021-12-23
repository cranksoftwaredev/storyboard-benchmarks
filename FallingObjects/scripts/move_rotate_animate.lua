require 'sbperftest'
require 'movement'
require 'utility'

local screenSize
local screenKeys = {"screen_width", "screen_height"}
local clones = 1
local cloneTable = {}

local function CBIncreaseObjects(mapargs, step, ...)
  clones = (2 ^ step)
  for index = 1, #(...) do
    local v = (...)[index]
    local template = 'moving_' .. v
    for i = 1, clones - 1 do
      local cloneName = 'clone_' .. v .. i
      if cloneTable[index] == nil then
        cloneTable[index] = {}
      end
      if cloneTable[index][i] == nil then
        gre.clone_object(template, cloneName, v .. '_move_layer')
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
  end
  gre.set_data(data)
end

local function CBUpdateData(mapargs, move, rotate, alpha, ...)
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
    local posY = gre.get_value('Animation_Y')
    
    for i = 1, #controlTable do
      data[controlTable[i] .. '.grd_y'] = posY
    end
  end
  if (rotate) then
    data.angle = gre.get_value('Animation_angle')
    data.txt_angle = gre.get_value('Animation_txt_angle')
  end
  if (alpha) then
    data.alpha = gre.get_value('Animation_alpha')
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

local function CBAnimate(mapargs, testTime)
  if screenSize == nil then
    screenSize = gre.env(screenKeys)
  end
  gre.set_value('Screen_height',screenSize[screenKeys[2]])
  gre.set_value('Animation_length', testTime)
  gre.animation_trigger('Falling')
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
local fill_move_animate = {}

function fill_move_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[1])
  CBAnimate(mapargs, durationTable[1])
end
function fill_move_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[1], controlTables[1])
end
function fill_move_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[1])
  CBReset(mapargs, controlTables[1])
  CBAnimate(mapargs, durationTable[1])
end
function fill_move_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[1])
end

sbperftest.RegisterPerfTest('fill_move_animate',fill_move_animate, stepTable[1], durationTable[1])

local fill_move_rotate_animate = {}

function fill_move_rotate_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[1])
  CBAnimate(mapargs, durationTable[1])
end
function fill_move_rotate_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[1], controlTables[1])
end
function fill_move_rotate_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[1])
  CBReset(mapargs, controlTables[1])
  CBAnimate(mapargs, durationTable[1])
end
function fill_move_rotate_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[1])
end

sbperftest.RegisterPerfTest('fill_move_rotate_animate',fill_move_rotate_animate, stepTable[1], durationTable[1])

--Rects
local rect_move_animate = {}

function rect_move_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[2])
  CBAnimate(mapargs, durationTable[1])
end
function rect_move_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[1], controlTables[2])
end
function rect_move_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[2])
  CBReset(mapargs, controlTables[2])
  CBAnimate(mapargs, durationTable[1])
end
function rect_move_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[2])
end

sbperftest.RegisterPerfTest('rect_move_animate',rect_move_animate, stepTable[1], durationTable[1])

local rect_move_rotate_animate = {}

function rect_move_rotate_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[2])
  CBAnimate(mapargs, durationTable[1])
end
function rect_move_rotate_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[1], controlTables[2])
end
function rect_move_rotate_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[2])
  CBReset(mapargs, controlTables[2])
  CBAnimate(mapargs, durationTable[1])
end
function rect_move_rotate_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[2])
end

sbperftest.RegisterPerfTest('rect_move_rotate_animate',rect_move_rotate_animate, stepTable[1], durationTable[1])

--Fill and rect
local fill_rect_move_animate = {}

function fill_rect_move_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[7])
  CBAnimate(mapargs, durationTable[2])
end
function fill_rect_move_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[1], controlTables[7])
end
function fill_rect_move_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[7])
  CBReset(mapargs, controlTables[7])
  CBAnimate(mapargs, durationTable[2])
end
function fill_rect_move_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[7])
end

sbperftest.RegisterPerfTest('fill_rect_move_animate',fill_rect_move_animate, stepTable[2], durationTable[2])

local fill_rect_move_rotate_animate = {}

function fill_rect_move_rotate_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[7])
  CBAnimate(mapargs, durationTable[2])
end
function fill_rect_move_rotate_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[1], controlTables[7])
end
function fill_rect_move_rotate_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[7])
  CBReset(mapargs, controlTables[7])
  CBAnimate(mapargs, durationTable[2])
end
function fill_rect_move_rotate_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[7])
end

sbperftest.RegisterPerfTest('fill_rect_move_rotate_animate',fill_rect_move_rotate_animate, stepTable[2], durationTable[2])

--imgs
local img_move_animate = {}

function img_move_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[3])
  CBAnimate(mapargs, durationTable[1])
end
function img_move_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[1], controlTables[3])
end
function img_move_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[3])
  CBReset(mapargs, controlTables[3])
  CBAnimate(mapargs, durationTable[1])
end
function img_move_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[3])
end

sbperftest.RegisterPerfTest('img_move_animate',img_move_animate, stepTable[1], durationTable[1])

local img_move_rotate_animate = {}

function img_move_rotate_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[3])
  CBAnimate(mapargs, durationTable[1])
end
function img_move_rotate_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[1], controlTables[3])
end
function img_move_rotate_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[3])
  CBReset(mapargs, controlTables[3])
  CBAnimate(mapargs, durationTable[1])
end
function img_move_rotate_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[3])
end

sbperftest.RegisterPerfTest('img_move_rotate_animate',img_move_rotate_animate, stepTable[1], durationTable[1])

--txt
local txt_move_animate = {}

function txt_move_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[4])
  CBAnimate(mapargs, durationTable[1])
end
function txt_move_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[1], controlTables[4])
end
function txt_move_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[4])
  CBReset(mapargs, controlTables[4])
  CBAnimate(mapargs, durationTable[1])
end
function txt_move_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[4])
end

sbperftest.RegisterPerfTest('txt_move_animate',txt_move_animate, stepTable[1], durationTable[1])

local txt_move_rotate_animate = {}

function txt_move_rotate_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[4])
  CBAnimate(mapargs, durationTable[1])
end
function txt_move_rotate_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[1], controlTables[4])
end
function txt_move_rotate_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[4])
  CBReset(mapargs, controlTables[4])
  CBAnimate(mapargs, durationTable[1])
end
function txt_move_rotate_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[4])
end

sbperftest.RegisterPerfTest('txt_move_rotate_animate',txt_move_rotate_animate, stepTable[1], durationTable[1])

--img and txt
local img_txt_move_animate = {}

function img_txt_move_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[6])
  CBAnimate(mapargs, durationTable[2])
end
function img_txt_move_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[1], controlTables[6])
end
function img_txt_move_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[6])
  CBReset(mapargs, controlTables[6])
  CBAnimate(mapargs, durationTable[2])
end
function img_txt_move_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[6])
end

sbperftest.RegisterPerfTest('img_txt_move_animate',img_txt_move_animate, stepTable[2], durationTable[2])

local img_txt_move_rotate_animate = {}

function img_txt_move_rotate_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[6])
  CBAnimate(mapargs, durationTable[2])
end
function img_txt_move_rotate_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[1], controlTables[6])
end
function img_txt_move_rotate_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[6])
  CBReset(mapargs, controlTables[6])
  CBAnimate(mapargs, durationTable[2])
end
function img_txt_move_rotate_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[6])
end

sbperftest.RegisterPerfTest('img_txt_move_rotate_animate',img_txt_move_rotate_animate, stepTable[2], durationTable[2])

--Fill, rect, img and txt
local fill_rect_img_txt_move_animate = {}

function fill_rect_img_txt_move_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[8])
  CBAnimate(mapargs, durationTable[3])
end
function fill_rect_img_txt_move_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[1], controlTables[8])
end
function fill_rect_img_txt_move_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[8])
  CBReset(mapargs, controlTables[8])
  CBAnimate(mapargs, durationTable[3])
end
function fill_rect_img_txt_move_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[8])
end

sbperftest.RegisterPerfTest('fill_rect_img_txt_move_animate',fill_rect_img_txt_move_animate,stepTable[3], durationTable[3])

local fill_rect_img_txt_move_rotate_animate = {}

function fill_rect_img_txt_move_rotate_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[8])
  CBAnimate(mapargs, durationTable[3])
end
function fill_rect_img_txt_move_rotate_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[1], controlTables[8])
end
function fill_rect_img_txt_move_rotate_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[8])
  CBReset(mapargs, controlTables[8])
  CBAnimate(mapargs, durationTable[3])
end
function fill_rect_img_txt_move_rotate_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[8])
end

sbperftest.RegisterPerfTest('fill_rect_img_txt_move_rotate_animate',fill_rect_img_txt_move_rotate_animate,stepTable[3], durationTable[3])

--arcs
local arc_move_animate = {}

function arc_move_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[5])
  CBAnimate(mapargs, durationTable[1])
end
function arc_move_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[1], controlTables[5])
end
function arc_move_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[5])
  CBReset(mapargs, controlTables[5])
  CBAnimate(mapargs, durationTable[1])
end
function arc_move_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[5])
end

sbperftest.RegisterPerfTest('arc_move_animate',arc_move_animate, stepTable[1], durationTable[1])

local arc_move_rotate_animate = {}

function arc_move_rotate_animate.CBSetup(mapargs)
  CBReset(mapargs, controlTables[5])
  CBAnimate(mapargs, durationTable[1])
end
function arc_move_rotate_animate.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[1], controlTables[5])
end
function arc_move_rotate_animate.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[5])
  CBReset(mapargs, controlTables[5])
  CBAnimate(mapargs, durationTable[1])
end
function arc_move_rotate_animate.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[5])
end

sbperftest.RegisterPerfTest('arc_move_rotate_animate',arc_move_rotate_animate, stepTable[1], durationTable[1])

--Alpha

--Fills
local fill_move_animate_alpha = {}

function fill_move_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[1])
  CBAnimate(mapargs, durationTable[1])
end
function fill_move_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[2], controlTables[1])
end
function fill_move_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[1])
  CBReset(mapargs, controlTables[1])
  CBAnimate(mapargs, durationTable[1])
end
function fill_move_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[1])
end

sbperftest.RegisterPerfTest('fill_move_animate_alpha',fill_move_animate_alpha, stepTable[1], durationTable[1])

local fill_move_rotate_animate_alpha = {}

function fill_move_rotate_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[1])
  CBAnimate(mapargs, durationTable[1])
end
function fill_move_rotate_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[2], controlTables[1])
end
function fill_move_rotate_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[1])
  CBReset(mapargs, controlTables[1])
  CBAnimate(mapargs, durationTable[1])
end
function fill_move_rotate_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[1])
end

sbperftest.RegisterPerfTest('fill_move_rotate_animate_alpha',fill_move_rotate_animate_alpha, stepTable[1], durationTable[1])

--Rects
local rect_move_animate_alpha = {}

function rect_move_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[2])
  CBAnimate(mapargs, durationTable[1])
end
function rect_move_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[2], controlTables[2])
end
function rect_move_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[2])
  CBReset(mapargs, controlTables[2])
  CBAnimate(mapargs, durationTable[1])
end
function rect_move_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[2])
end

sbperftest.RegisterPerfTest('rect_move_animate_alpha',rect_move_animate_alpha, stepTable[1], durationTable[1])

local rect_move_rotate_animate_alpha = {}

function rect_move_rotate_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[2])
  CBAnimate(mapargs, durationTable[1])
end
function rect_move_rotate_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[2], controlTables[2])
end
function rect_move_rotate_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[2])
  CBReset(mapargs, controlTables[2])
  CBAnimate(mapargs, durationTable[1])
end
function rect_move_rotate_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[2])
end

sbperftest.RegisterPerfTest('rect_move_rotate_animate_alpha',rect_move_rotate_animate_alpha, stepTable[1], durationTable[1])

--Fill and rect
local fill_rect_move_animate_alpha = {}

function fill_rect_move_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[7])
  CBAnimate(mapargs, durationTable[2])
end
function fill_rect_move_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[2], controlTables[7])
end
function fill_rect_move_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[7])
  CBReset(mapargs, controlTables[7])
  CBAnimate(mapargs, durationTable[2])
end
function fill_rect_move_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[7])
end

sbperftest.RegisterPerfTest('fill_rect_move_animate_alpha',fill_rect_move_animate_alpha, stepTable[2], durationTable[2])

local fill_rect_move_rotate_animate_alpha = {}

function fill_rect_move_rotate_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[7])
  CBAnimate(mapargs, durationTable[2])
end
function fill_rect_move_rotate_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[2], controlTables[7])
end
function fill_rect_move_rotate_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[7])
  CBReset(mapargs, controlTables[7])
  CBAnimate(mapargs, durationTable[2])
end
function fill_rect_move_rotate_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[7])
end

sbperftest.RegisterPerfTest('fill_rect_move_rotate_animate_alpha',fill_rect_move_rotate_animate_alpha, stepTable[2], durationTable[2])

--imgs
local img_move_animate_alpha = {}

function img_move_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[3])
  CBAnimate(mapargs, durationTable[1])
end
function img_move_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[2], controlTables[3])
end
function img_move_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[3])
  CBReset(mapargs, controlTables[3])
  CBAnimate(mapargs, durationTable[1])
end
function img_move_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[3])
end

sbperftest.RegisterPerfTest('img_move_animate_alpha',img_move_animate_alpha, stepTable[1], durationTable[1])

local img_move_rotate_animate_alpha = {}

function img_move_rotate_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[3])
  CBAnimate(mapargs, durationTable[1])
end
function img_move_rotate_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[2], controlTables[3])
end
function img_move_rotate_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[3])
  CBReset(mapargs, controlTables[3])
  CBAnimate(mapargs, durationTable[1])
end
function img_move_rotate_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[3])
end

sbperftest.RegisterPerfTest('img_move_rotate_animate_alpha',img_move_rotate_animate_alpha, stepTable[1], durationTable[1])

--txt

local txt_move_animate_alpha = {}

function txt_move_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[4])
  CBAnimate(mapargs, durationTable[1])
end
function txt_move_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[2], controlTables[4])
end
function txt_move_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[4])
  CBReset(mapargs, controlTables[4])
  CBAnimate(mapargs, durationTable[1])
end
function txt_move_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[4])
end

sbperftest.RegisterPerfTest('txt_move_animate_alpha',txt_move_animate_alpha, stepTable[1], durationTable[1])

local txt_move_rotate_animate_alpha = {}

function txt_move_rotate_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[4])
  CBAnimate(mapargs, durationTable[1])
end
function txt_move_rotate_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[2], controlTables[4])
end
function txt_move_rotate_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[4])
  CBReset(mapargs, controlTables[4])
  CBAnimate(mapargs, durationTable[1])
end
function txt_move_rotate_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[4])
end

sbperftest.RegisterPerfTest('txt_move_rotate_animate_alpha',txt_move_rotate_animate_alpha, stepTable[1], durationTable[1])

--img and txt
local img_txt_move_animate_alpha = {}

function img_txt_move_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[6])
  CBAnimate(mapargs, durationTable[2])
end
function img_txt_move_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[2], controlTables[6])
end
function img_txt_move_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[6])
  CBReset(mapargs, controlTables[6])
  CBAnimate(mapargs, durationTable[2])
end
function img_txt_move_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[6])
end

sbperftest.RegisterPerfTest('img_txt_move_animate_alpha',img_txt_move_animate_alpha, stepTable[2], durationTable[2])

local img_txt_move_rotate_animate_alpha = {}

function img_txt_move_rotate_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[6])
  CBAnimate(mapargs, durationTable[2])
end
function img_txt_move_rotate_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[2], controlTables[6])
end
function img_txt_move_rotate_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[6])
  CBReset(mapargs, controlTables[6])
  CBAnimate(mapargs, durationTable[2])
end
function img_txt_move_rotate_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[6])
end

sbperftest.RegisterPerfTest('img_txt_move_rotate_animate_alpha',img_txt_move_rotate_animate_alpha, stepTable[2], durationTable[2])

--Fill, rect, img and txt
local fill_rect_img_txt_move_animate_alpha = {}

function fill_rect_img_txt_move_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[8])
  CBAnimate(mapargs, durationTable[3])
end
function fill_rect_img_txt_move_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[2], controlTables[8])
end
function fill_rect_img_txt_move_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[8])
  CBReset(mapargs, controlTables[8])
  CBAnimate(mapargs, durationTable[3])
end
function fill_rect_img_txt_move_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[8])
end

sbperftest.RegisterPerfTest('fill_rect_img_txt_move_animate_alpha',fill_rect_img_txt_move_animate_alpha,stepTable[3], durationTable[3])

local fill_rect_img_txt_move_rotate_animate_alpha = {}

function fill_rect_img_txt_move_rotate_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[8])
  CBAnimate(mapargs, durationTable[3])
end
function fill_rect_img_txt_move_rotate_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[2], controlTables[8])
end
function fill_rect_img_txt_move_rotate_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[8])
  CBReset(mapargs, controlTables[8])
  CBAnimate(mapargs, durationTable[3])
end
function fill_rect_img_txt_move_rotate_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[8])
end

sbperftest.RegisterPerfTest('fill_rect_img_txt_move_rotate_animate_alpha',fill_rect_img_txt_move_rotate_animate_alpha,stepTable[3], durationTable[3])

--arcs
local arc_move_animate_alpha = {}

function arc_move_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[5])
  CBAnimate(mapargs, durationTable[1])
end
function arc_move_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, false, alphaTable[2], controlTables[5])
end
function arc_move_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[5])
  CBReset(mapargs, controlTables[5])
  CBAnimate(mapargs, durationTable[1])
end
function arc_move_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[5])
end

sbperftest.RegisterPerfTest('arc_move_animate_alpha',arc_move_animate_alpha, stepTable[1], durationTable[1])

local arc_move_rotate_animate_alpha = {}

function arc_move_rotate_animate_alpha.CBSetup(mapargs)
  CBReset(mapargs, controlTables[5])
  CBAnimate(mapargs, durationTable[1])
end
function arc_move_rotate_animate_alpha.CBUpdate(mapargs, elapsedTime)
  CBUpdateData(mapargs, true, true, alphaTable[2], controlTables[5])
end
function arc_move_rotate_animate_alpha.CBStep(mapargs, step)
  CBIncreaseObjects(mapargs, step, controlTables[5])
  CBReset(mapargs, controlTables[5])
  CBAnimate(mapargs, durationTable[1])
end
function arc_move_rotate_animate_alpha.CBTeardown(mapargs)
  for i=1,#cloneTable do
    ControlListTeardown(cloneTable[i], true)
  end
  cloneTable = {}
  clones = 1
  CBReset(mapargs, controlTables[5])
end

sbperftest.RegisterPerfTest('arc_move_rotate_animate_alpha',arc_move_rotate_animate_alpha, stepTable[1], durationTable[1])