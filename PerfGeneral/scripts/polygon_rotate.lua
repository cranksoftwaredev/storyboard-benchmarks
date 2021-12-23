require "sbperftest"
require "utility"

-- This test validates the behaviour of drawing a series of expanding polygons
local layerInfo 

--The maximum line width to use in tests
local MAX_LINE_WIDTH = 5    
--The trend x point increment to use in tests
local TREND_POINT_INCREMENT = 5        
--The maximum number of points to use in our star/closed polygon test
local MAX_CLOSED_POLYGON_POINTS = 10

local controlList = {}

local function HideReferenceControls()
  gre.set_control_attrs("animated_polygons_layer.filled_poly_ref",{ hidden = true})
  gre.set_control_attrs("animated_polygons_layer.poly_ref",{ hidden = true})
end

local function MakePolygonPoints(numberOfSides, width, height, inset)
    local Xcenter = width / 2
    local Ycenter = height / 2
  
  -- Make the size match the smaller of width/height and then inset it
  local size = Xcenter
  if(Ycenter < Xcenter) then
    size = Ycenter
  end
  if(inset ~= nil) then
    size = size - inset
  end
  
  local xdata = {} 
  local ydata = {} 
  
  table.insert(xdata, Xcenter +  size * math.cos(0))
  table.insert(ydata, Ycenter +  size *  math.sin(0))         
 
  for i = 1, numberOfSides do
    local arcPoint = i * 2 * math.pi / numberOfSides
    table.insert(xdata, Xcenter + size * math.cos(arcPoint))
    table.insert(ydata, Ycenter + size * math.sin(arcPoint));
  end
 
  return gre.poly_string(xdata, ydata)
end

local function CBCreatePolyControls(reference_control_name, layer_name, name_fmt, fill)
  if(fill == nil) then
    fill = false
  end
  
  local controlInfo = gre.get_control_attrs(reference_control_name, "height")
  layerInfo = gre.get_layer_attrs(layer_name, "width", "height")

  local controlWidthHeight = controlInfo.height
  
  local numControlsPerRow = math.floor(layerInfo.width / controlWidthHeight)
  local numControls = math.floor(layerInfo.height / controlWidthHeight) * numControlsPerRow

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
    if(not fill) then
      local lineWidth = 1 + (i % (MAX_LINE_WIDTH-1))
      gre.set_value(fqn .. ".width", lineWidth)
    end
    
    local numPoints = 3 + (i % (MAX_CLOSED_POLYGON_POINTS - 3)) 
    local points = MakePolygonPoints(numPoints, controlWidthHeight, controlWidthHeight, 2)
    gre.set_value(fqn .. ".points", points)

    data.fill = fill
    data.rotation = 0
    controlList[fqn] = data
  end
  
  HideReferenceControls()
end

local function CBPolyUpdate(mapargs, elapsedTime)
  local new_data = {}
  for control,data in pairs(controlList) do
    data.rotation = data.rotation + 10
    new_data[control .. ".rot"] = data.rotation
   end
  gre.set_data(new_data)
end

local rotated_poly = {}
function rotated_poly.CBSetup(mapargs)
  CBCreatePolyControls("animated_polygons_layer.poly_ref", "animated_polygons_layer", "poly_%d")
end
function rotated_poly.CBUpdate(mapargs, elapsedTime)
  CBPolyUpdate(mapargs, elapsedTime)
end
function rotated_poly.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("polygon_rotated", rotated_poly)

local rotated_filled_poly = {}
function rotated_filled_poly.CBSetup(mapargs)
  CBCreatePolyControls("animated_polygons_layer.filled_poly_ref", "animated_polygons_layer", "poly_%d")
end
function rotated_filled_poly.CBUpdate(mapargs, elapsedTime)
  CBPolyUpdate(mapargs, elapsedTime)
end
function rotated_filled_poly.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("polygon_rotated_filled", rotated_filled_poly)


