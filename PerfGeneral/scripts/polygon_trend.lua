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

local function CBTrendCreateControls(reference_control_name, layer_name, name_fmt, fill)
  if(fill == nil) then
    fill = false
  end
  
  local controlInfo = gre.get_control_attrs(reference_control_name, "height")
  layerInfo = gre.get_layer_attrs(layer_name, "width", "height")
  
  local numControls = math.floor(layerInfo.height / controlInfo.height)
  local yOffset = 0

  for i=1,numControls do
    local name = string.format(name_fmt, i)
    local fqn = string.format("%s.%s", layer_name, name)
    local data = {}
    data.y = yOffset 
    data.x = 0
    data.height = controlInfo.height
    data.width = layerInfo.width
    data.hidden = 0
    
    gre.clone_control(reference_control_name, name, layer_name, data)
    if(not fill) then
      local lineWidth = 1 + (i % (MAX_LINE_WIDTH-1))
      gre.set_value(fqn .. ".width", lineWidth)
    end
    
    data.points = {}
    data.fill = fill
    controlList[fqn] = data
    
    yOffset = yOffset + controlInfo.height
  end
  
  HideReferenceControls()
end

local function CBTrendUpdate(mapargs, elapsedTime)
  local new_points = {}
  
  for control,data in pairs(controlList) do
    local points = data.points
    
    local nextX, nextY
    if(#points == 0) then
      nextX = 0
      nextY = data.height
    else
      local lastPoint = points[#points]
      nextY = lastPoint.y + data.height
      nextX = lastPoint.x + TREND_POINT_INCREMENT
      if(nextY > data.height) then
        nextY = 0
      end
      if(nextX > data.width) then   --Reset
        data.points = {}
        points = data.points
        nextX = 0
        nextY = data.height
      end
    end
    
    points[#points + 1] = { x=nextX, y=nextY }      
    
    -- Close the polygon by extending 1 past the end
    if(data.fill) then      
      points[#points+1] = { x=nextX+1, y=data.height+1}
    end
        
    local var = control .. ".points"
    new_points[var] = gre.poly_string(points)

    if(data.fill) then
      points[#points] = nil
    end

  end
  gre.set_data(new_points)
end

local trend_poly = {}
function trend_poly.CBSetup(mapargs)
  CBTrendCreateControls("animated_polygons_layer.poly_ref", "animated_polygons_layer", "poly_%d")
end
function trend_poly.CBUpdate(mapargs, elapsedTime)
  CBTrendUpdate(mapargs, elapsedTime)
end
function trend_poly.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("polygon_trend", trend_poly)

local trend_filled_poly = {}
function trend_filled_poly.CBSetup(mapargs)
  CBTrendCreateControls("animated_polygons_layer.filled_poly_ref", "animated_polygons_layer", "poly_%d", true)
end
function trend_filled_poly.CBUpdate(mapargs, elapsedTime)
  CBTrendUpdate(mapargs, elapsedTime)
end
function trend_filled_poly.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("polygon_trend_filled", trend_filled_poly)
