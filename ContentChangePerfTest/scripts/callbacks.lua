---
-- This test sets up two layers with the same 'visual' content but one layer's content
-- is composed of a control with lots of variables (that aren't changing) and the other
-- layer's content is composed of a control with only a single variable.
-- 
-- The test toggles the same variable on one control in both scenarios and measures the 
-- cost difference of synchronizing all of those additional variables that aren't changing.
-- 
-- The intent of this test is to demonstrate value in data synchronization changes


function CreateClonedContent(fqnTemplateName, fqnLayer)
  local PAD = 2
  local newFQNList = {}
  
  local layerBaseName = string.match(fqnLayer, ".+%.([^%.]*)")
  
  local baseName = string.match(fqnTemplateName, ".+%.([^%.]*)")

  local fmt = baseName .. "%d"
  
  local cInfo = gre.get_control_attrs(fqnTemplateName, "x", "y", "width", "height")
  local lInfo = gre.get_layer_attrs(fqnLayer, "width", "height")

  -- Make a wack of controls running left to right
  local attrs = {}
  attrs.x = PAD
  attrs.y = PAD
  attrs.hidden = false
  
  local i = 1
  while(true) do
    local newName = string.format(fmt, i)
    local newFQN = fqnLayer .. "." .. newName
    table.insert(newFQNList, newFQN)
      
    gre.clone_object(fqnTemplateName, newName, layerBaseName, attrs)
    
    attrs.x = attrs.x + cInfo.width + PAD
    if(attrs.x > lInfo.width) then
      attrs.x = PAD
      attrs.y = attrs.y + cInfo.height + PAD   
      
      --Only make what we can see .. up to the max
      if(attrs.y > lInfo.height) then
        break
      end
    end
    
    i = i + 1
  end
  
  -- Hide the template
  gre.set_control_attrs(fqnTemplateName, { hidden = true } )
  
  return newFQNList
end

local gClonedDynamicControls
local gClonedFixedControls
local gToggleControlName
local gStartTime, gEndTime, gFrames

--- @param gre#context mapargs
function CBInitializeContent(mapargs)
  gClonedFixedControls = CreateClonedContent("FixedLayer.FixedTemplate", "Screen.FixedLayer")
  gClonedDynamicControls = CreateClonedContent("DynamicLayer.DynamicTemplate", "Screen.DynamicLayer")

  -- Now hide the layers prior to testing
  gre.set_layer_attrs("Screen.FixedLayer", { hidden = true })
  gre.set_layer_attrs("Screen.DynamicLayer", { hidden = true })
end

function ToggleValue(varName) 
  local curValue = gre.get_value(varName)
  if(curValue == 0x000000) then
    curValue = 0xffffff
  else
    curValue = 0x000000
  end
  gre.set_value(varName, curValue)
end

function CBNextTest()
  if(gToggleControlName == nil) then
    gToggleControlName = gClonedDynamicControls[1]     
    gre.set_layer_attrs("Screen.FixedLayer", { hidden = true })
    gre.set_layer_attrs("Screen.DynamicLayer", { hidden = false })
  elseif(gToggleControlName == gClonedDynamicControls[1]) then
    gToggleControlName = gClonedFixedControls[1]     
    gre.set_layer_attrs("Screen.FixedLayer", { hidden = false })
    gre.set_layer_attrs("Screen.DynamicLayer", { hidden = true })
--  elseif(gToggleControlName == gClonedFixedControls[1]) then
--    gToggleControlName = gClonedDynamicControls[1]     
--    gre.set_layer_attrs("Screen.FixedLayer", { hidden = false })
--    gre.set_layer_attrs("Screen.DynamicLayer", { hidden = true })
  else 
    gre.send_event("gre.quit")
  end
  
  gFrames = 10000
  gStartTime = gre.ustime(true)  
  gre.send_event("next_frame")
end

function CBReportResults()
  gEndTime = gre.ustime(true)
  execute_time_ms = (gEndTime - gStartTime) / 1000
  gre.log_perf_stat("ContentChangePerfTest", gToggleControlName, tostring(execute_time_ms), "ms");

  CBNextTest()  
end

--- @param gre#context mapargs
function CBNextFrame(mapargs)
  local varName = gToggleControlName .. ".color"
  ToggleValue(varName)
  
  gFrames = gFrames - 1
  if(gFrames <= 0) then
    CBReportResults()  
  else
    gre.send_event("next_frame")
  end
end

