-- This is a collection of utility functions that provide consistent behaviour
-- for the construction and destruction of controls to be used for test scenarios._G

---Delete a list of controls created by cloning
---@param controlList A key/value table where the key is the control name and the value is some user data
---@param isArray (optional) If true, then controlList is interpreted as an array of just control names to delete 
function ControlListTeardown(controlList, isArray)
  if(controlList == nil) then
    return
  end
  
  if(isArray == true) then
    for i=1,#controlList do
      gre.delete_control(controlList[i])
    end
  else
    for control,data in pairs(controlList) do
      gre.delete_control(control)
    end
  end
end

---Create a tiled set of controls that cover an entire layer area
---@param reference_control_name The name of the control to clone
---@param layer_name The name of the layer to clone onto
---@param name_fmt A format string with a single %d for the cloned names
---@return A key/value table of control names and control data (position) 
function CreateTiledControls(reference_control_name, layer_name, name_fmt)
  local controlInfo = gre.get_control_attrs(reference_control_name, "height")
  local layerInfo = gre.get_layer_attrs(layer_name, "width", "height")

  local controlWidthHeight = controlInfo.height
  
  local numControlsPerRow = math.floor(layerInfo.width / controlWidthHeight)
  local numControls = math.floor(layerInfo.height / controlWidthHeight) * numControlsPerRow

  -- Hide the template
  gre.set_control_attrs(reference_control_name, { hidden = 1 })

  -- Create the mess of controls  
  local controlList = {}
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

    controlList[fqn] = data
  end
  
end

function CreateNumControls(reference_control_name, layer_name, name_fmt, numControls)
  local controlInfo = gre.get_control_attrs(reference_control_name, "height")
  local layerInfo = gre.get_layer_attrs(layer_name, "width", "height")

  local controlWidthHeight = controlInfo.height
  
  local numControlsPerRow = numControls
  local numControls = numControls
  
  -- Hide the template
  gre.set_control_attrs(reference_control_name, { hidden = 1 })

  -- Create the mess of controls  
  local controlList = {}
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

    controlList[fqn] = data
  end
  
  return controlList
end


--# HSV values in [0..1[
--# returns [r, g, b] values from 0 to 255
local function HSVToRGB(h, s, v)
  local h_i = math.floor(h*6)
  local f = h*6 - h_i
  local p = v * (1 - s)
  local q = v * (1 - f*s)
  local t = v * (1 - (1 - f) * s)
  if(h_i == 0) then
    r, g, b = v, t, p 
  elseif(h_i == 1) then
    r, g, b = q, v, p 
  elseif(h_i == 2) then
    r, g, b = p, v, t 
  elseif(h_i == 3) then
    r, g, b = p, q, v 
  elseif(h_i == 4) then
    r, g, b = t, p, v 
  elseif(h_i == 5) then
    r, g, b = v, p, q
  end
  local rgbstr = string.format("%02x%02x%02x", math.floor(r*256), math.floor(g*256), math.floor(b*256))
  return tonumber(rgbstr, 16)
end

---Create an table array of numClrs distinct colors for use in test scenarios
---@param numClrs The number of colors to create in the table
---@return A table array of RGB colors
function MakeColorTable(numClrs)
  local golden_ratio_conjugate = 0.618033988749895
  local h = 1
  
  local clrTable = {}
  for i=1,numClrs do
    h = (h + golden_ratio_conjugate) % 1
    local rgb = HSVToRGB(h, 0.5, 0.95)
    table.insert(clrTable,rgb)
  end
  
  return clrTable
end

-- Split a rectangle into three pieces: half/quarter/quarter
local function SplitRect(x, y, width, height)
  if(width < 20 or height < 20) then
    return nil
  end
  local halfHeight = math.floor(height / 2)
  local otherHalfHeight = height - halfHeight
  
  local halfWidth = math.floor(width / 2)
  local otherHalfWidth = width - halfWidth
  
  local left = { x=x, y=y, height=height, width=halfWidth}
  local topRight = { x=x+halfWidth, y=y, height=halfHeight, width=otherHalfWidth}
  local bottomRight = { x=x+halfWidth, y=y+halfHeight, height=otherHalfHeight, width=otherHalfWidth}
 
  return { left, topRight, bottomRight }
end

--- Create a bisection list for this particular layer
---@param layer_name The name of the layer to split into bits
---@param square (optional) Normalize the returned values to be squared
---@return An array of {x,y,width,height} rectangles for the bisected area
function CreateBisectionList(layer_name, square)
  local layerInfo = gre.get_layer_attrs(layer_name, "width", "height")
  
  local bisectList = SplitRect(0, 0, layerInfo.width, layerInfo.height, square)
  if(bisectList == nil) then
    return nil
  end
  
  while(true) do
    local bisectSquare = bisectList[#bisectList] 
    local newBisect = SplitRect(bisectSquare.x, bisectSquare.y, bisectSquare.width, bisectSquare.height, square)
    if(newBisect == nil) then
      break
    end
    -- Replace the last square with the new one and add the sub squares
    bisectList[#bisectList] = newBisect[1]
    table.insert(bisectList, newBisect[2])
    table.insert(bisectList, newBisect[3])
  end
  
    -- If we are squaring, then normalize the size list
  if(square) then
    for i=1,#bisectList do
      local entry = bisectList[i]
      local delta = math.abs(entry.width - entry.height)
      if(entry.width < entry.height) then
        entry.y = entry.y + delta/2
        entry.height = entry.width
      else
        entry.x = entry.x + delta/2
        entry.width = entry.height
      end
    end
  end
  
  return bisectList
end
