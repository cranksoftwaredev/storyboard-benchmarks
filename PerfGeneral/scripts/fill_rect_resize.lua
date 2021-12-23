require "sbperftest"
require "utility"

-- This test validates the behaviour of drawing a series of concentric 
-- filled rectangles and outlined rectangles.
local MAX_FILLS = 100
local DELTA = 4

local controlList  = {}
local layerInfo 

local function HideReferenceControls()
  gre.set_control_attrs("animated_fills_rects_layer.rect_ref",{ hidden = true})
  gre.set_control_attrs("animated_fills_rects_layer.fill_ref",{ hidden = true})
end

local function CBCreateControls(reference_control_name, layer_name, name_fmt)
  layerInfo = gre.get_layer_attrs(layer_name, "width", "height")
  layerInfo.xMax = layerInfo.width / 2
  layerInfo.yMax = layerInfo.height / 2
  
  local clrs = MakeColorTable(MAX_FILLS)
  
  -- Initialize first rect to fill the layer
  local xPos = 0
  local yPos = 0
  local width = layerInfo.width
  local height = layerInfo.height
  
  local clrData = {}
  for i=1,MAX_FILLS do
    local name = string.format(name_fmt, i)
    local data = {}
    data.x = xPos
    data.y = yPos
    data.width = width
    data.height = height
    data.inc = DELTA
    data.hidden = false
    gre.clone_control(reference_control_name, name, layer_name, data)
    clrData[string.format("%s.%s.clr", layer_name, name)] = clrs[i]
    
    controlList[name] = data
        
    -- Advance to next position
    xPos = xPos + DELTA
    yPos = yPos + DELTA
    width = width - (2 * DELTA)
    height = height - (2 * DELTA) 
  end
  
  -- Set the colors
  gre.set_data(clrData)
  
  HideReferenceControls()
end

local function CBUpdate(mapargs, elapsedTime)
  for control,data in pairs(controlList) do
    data.x = data.x + data.inc
    data.y = data.y + data.inc
    -- Start moving in the opposite direction
    if(data.x >= layerInfo.xMax or data.y >= layerInfo.yMax or data.x < 0 or data.y < 0) then
      data.inc = -1 * data.inc
      data.x = data.x + (2 * data.inc)
      data.y = data.y + (2 * data.inc)
    end
    data.width = data.width - (2 * data.inc)
    data.height = data.height - (2 * data.inc) 
    
    gre.set_control_attrs(control, data)
  end
end


local fill_resize = {}
function fill_resize.CBSetup(mapargs)
  CBCreateControls("animated_fills_rects_layer.fill_ref", "animated_fills_rects_layer", "fill_%d")
end
function fill_resize.CBUpdate(mapargs, elapsedTime)
  CBUpdate(mapargs, elapsedTime)
end
function fill_resize.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("fill_resize", fill_resize)

local rect_resize = {}
function rect_resize.CBSetup(mapargs)
  CBCreateControls("animated_fills_rects_layer.rect_ref", "animated_fills_rects_layer", "rect_%d")
end
function rect_resize.CBUpdate(mapargs, elapsedTime)
  CBUpdate(mapargs, elapsedTime)
end
function rect_resize.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("rect_resize", rect_resize)

local CONTROL_WIDTH_HEIGHT = 50

local function CBCreateTiledControls(reference_control_name, layer_name, name_fmt)
  layerInfo = gre.get_layer_attrs(layer_name, "width", "height")
  
  local controlWidthHeight = CONTROL_WIDTH_HEIGHT
  local numControlsPerRow = math.floor(layerInfo.width / controlWidthHeight)
  local numControls = math.floor(layerInfo.height / controlWidthHeight) * numControlsPerRow
  
  local clrs = MakeColorTable(numControls)
  
  for i=1,numControls do
    local name = string.format(name_fmt, i)
    local fqn = string.format("%s.%s", layer_name, name)
    local data = {}

    data.x = ((i-1) % numControlsPerRow) * controlWidthHeight
    data.y = math.floor((i-1) / numControlsPerRow) * controlWidthHeight
    data.height = controlWidthHeight
    data.width = controlWidthHeight
    data.hidden = 0
    
    gre.clone_control(reference_control_name, name, layer_name, data)
    
    gre.set_value(fqn .. ".clr", clrs[i])

    controlList[fqn] = data
  end
    
  HideReferenceControls()
end

local hideShowCount = 1
local function CBHideShowUpdate(mapargs, elapsedTime)
  -- Roll the starting index for our flip each iteration
  hideShowCount = hideShowCount + 1
  local count = hideShowCount
  
  local newData = {}
  for control,data in pairs(controlList) do
    count = count + 1
    
    -- Change 1/3 of the values
    if((count % 3) == 0) then
      if(data.hidden == 1) then
        data.hidden = 0
      elseif(data.hidden == 0) then
        data.hidden = 1
      else
        data.hidden = not data.hidden
      end
    
      newData[control .. ".grd_hidden"] = data.hidden
    end
  end
  gre.set_data(newData)
end

local fill_hideshow = {}
function fill_hideshow.CBSetup(mapargs)
  CBCreateTiledControls("animated_fills_rects_layer.fill_ref", "animated_fills_rects_layer", "fill_%d")
end
function fill_hideshow.CBUpdate(mapargs, elapsedTime)
  CBHideShowUpdate(mapargs, elapsedTime)
end
function fill_hideshow.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("fill_hideshow", fill_hideshow)

