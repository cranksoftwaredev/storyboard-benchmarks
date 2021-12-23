--Functions for event driven movement

local screenSize
local screenKeys = {"screen_width", "screen_height"}
local controlsSized

function falling(elapsedTime, controlTable, mapargs, testTime)
  if screenSize == nil then
    screenSize = gre.env(screenKeys)
  end
  local speed = (screenSize[screenKeys[2]]) / testTime 
  local posTable = {}
  for i, v in ipairs(controlTable) do
    posTable[i] = elapsedTime * speed
  end
  return posTable
end

--A function that returns centralized positions of a variable number of controls
--Also a catch all for resetting variables to a default state
function reset(...)
  local variableTable = {}
  
  variableTable.angle = 0
  variableTable.txt_angle = 0
  variableTable.alpha = 255
  
  variableTable.Animation_Y = 0
  
  variableTable.Animation_angle = 0
  variableTable.Animation_txt_angle = 0
  variableTable.Animation_alpha = 255
  
  gre.set_data(variableTable)
  if (...) and type(...) == 'table' then
    local dataTable = {}
    for i, v in ipairs(...) do
      screenSize = gre.env(screenKeys)
      local controlSize = gre.get_control_attrs(v, "width", "height")
      dataTable['X' .. i] = screenSize[screenKeys[1]] / 2 - controlSize.width / 2
      dataTable['Y' .. i] = screenSize[screenKeys[2]] / 2 - controlSize.height / 2
      local controlsDim = {}
      local largerDim
      local renderWidth = gre.get_value('render_width')
      local renderHeight = gre.get_value('render_height')
      if renderWidth > renderHeight then
        largerDim = renderWidth
      else
        largerDim = renderHeight
      end
      controlsDim['width'] = math.ceil(math.sqrt(2) * largerDim)
      controlsDim['height'] = math.ceil(math.sqrt(2) * largerDim)
      gre.set_data(controlsDim)
    end
    return dataTable
  end
end