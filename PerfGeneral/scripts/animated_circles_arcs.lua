require "sbperftest"
require "utility"

local maxResizeList = {}
local controlList = {}

local function HideReferenceControls()
  gre.set_control_attrs("circle_change_layer.circle_ref", { hidden = true })
  gre.set_control_attrs("circle_change_layer.arc_ref", { hidden = true })
end

local function CBCircleSetup(mapargs, ref, square)
  local sizeList = CreateBisectionList("circle_change_layer", square)
  controlList = CreateNumControls(ref, "circle_change_layer", "circle_%d", #sizeList)
      
  local i = 1
  for control,data in pairs(controlList) do
    maxResizeList[control] = sizeList[i]
    --print("Create at %d,%d %d-%d", sizeList[i].x, sizeList[i].y, sizeList[i].width, sizeList[i].height)
    gre.set_control_attrs(control, sizeList[i])
    i = i + 1
  end
  
  HideReferenceControls()
end

local function CBUpdateCircles(mapargs, elapsedTime, updateAngle, updateWidth)
  local data = {}

  if(updateAngle) then
    local arcAngle = math.sin(elapsedTime / 200.0) * 180.0 + 90.0 
    data.arc_angle = arcAngle
  end

  if(updateWidth) then
    local arcWidth = math.sin(elapsedTime / 800.0) * 60.0 + 64.0  
    data.arc_width = arcWidth 
  end
  
  gre.set_data(data)
end

-- Circles
local circle_width_change = {}
function circle_width_change.CBSetup(mapargs)
  CBCircleSetup(mapargs, "circle_change_layer.circle_ref", true)
end
function circle_width_change.CBUpdate(mapargs, elapsedTime)
  CBUpdateCircles(mapargs, elapsedTime, false, true)
end
function circle_width_change.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("circle_width_change", circle_width_change)

-- Arc's that are circles
local arc_angle_change = {}
function arc_angle_change.CBSetup(mapargs)
  CBCircleSetup(mapargs, "circle_change_layer.arc_ref", true)
end
function arc_angle_change.CBUpdate(mapargs, elapsedTime)
  CBUpdateCircles(mapargs, elapsedTime, true, false)
end
function arc_angle_change.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("arc_angle_change", arc_angle_change)

local arc_angle_width_change = {}
function arc_angle_width_change.CBSetup(mapargs)
  CBCircleSetup(mapargs, "circle_change_layer.arc_ref", true)
end
function arc_angle_width_change.CBUpdate(mapargs, elapsedTime)
  CBUpdateCircles(mapargs, elapsedTime, true, true)
end
function arc_angle_width_change.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("arc_angle_width_change", arc_angle_width_change)

-- Ellipses
local ellipse_width_change = {}
function ellipse_width_change.CBSetup(mapargs)
  CBCircleSetup(mapargs, "circle_change_layer.circle_ref")
end
function ellipse_width_change.CBUpdate(mapargs, elapsedTime)
  CBUpdateCircles(mapargs, elapsedTime, false, true)
end
function ellipse_width_change.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("ellipse_width_change", ellipse_width_change)

local ellipse_angle_change = {}
function ellipse_angle_change.CBSetup(mapargs)
  CBCircleSetup(mapargs, "circle_change_layer.arc_ref")
end
function ellipse_angle_change.CBUpdate(mapargs, elapsedTime)
  CBUpdateCircles(mapargs, elapsedTime, true, false)
end
function ellipse_angle_change.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("ellipse_angle_change", ellipse_angle_change)

local ellipse_angle_width_change = {}
function ellipse_angle_width_change.CBSetup(mapargs)
  CBCircleSetup(mapargs, "circle_change_layer.arc_ref")
end
function ellipse_angle_width_change.CBUpdate(mapargs, elapsedTime)
  CBUpdateCircles(mapargs, elapsedTime, true, true)
end
function ellipse_angle_width_change.CBTeardown(mapargs)
  ControlListTeardown(controlList)
  controlList = {}
end
sbperftest.RegisterPerfTest("ellipse_angle_width_change", ellipse_angle_width_change)


