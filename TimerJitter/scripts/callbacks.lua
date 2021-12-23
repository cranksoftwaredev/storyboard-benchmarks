-- This is very much based on the HTML based sample:
-- http://ejohn.org/blog/analyzing-timer-performance/

local numTimers = 1       -- Number of timers to run concurrently
local maxTimers = 128
--local maxTimers = 1
local numRecurses = 100   -- Number of iterations to run test
local delay = 20           -- Delay period in ms 

local draw = true

--local timer = gre.timer_set_interval
local timer = gre.timer_set_timeout

-- An array of result entries:
-- { label, data }
-- Where:
-- * label Is the string label for the series
-- * data  Is an array of { x, y } tables where the y represents the average delay
--   that should be compared against the desired 'delay' target
local allResults = {}

-- Create a timer and set up a measurement in a closure as a callback
function makeTimer(id, done) 
  local depth = 0
  local results = {}
  local timerId = nil
  
  local xPosVar = string.format("TestLayer.dot%d.grd_x", id)
  gre.set_value(xPosVar, 10)
  
  local timerCall;
  timerCall = function() 
    depth = depth + 1
    if(depth < numRecurses) then
      if(draw) then
        gre.set_value(xPosVar, depth + 10)
      end
      
      table.insert(results,gre.mstime())
      -- Re-arm the timer if we are a one-shot  
      if(timer == gre.timer_set_timeout) then
        gre.timer_set_timeout(timerCall, delay)
      end
      
    else
      -- Cancel the timer if we are not a one-shot
      if(timer == gre.timer_set_interval) then
        gre.timer_clear_interval(timerId)
      end
      
      table.insert(done, results)
      if(#done == numTimers) then
        endTest(done)  
      end
    end
  end
  
  timerId = timer(timerCall, delay)
end

-- This is used to kick off the number of timers we want to measure
function startTest() 
  local done = {}
  for i=1,numTimers do
    makeTimer(1, done)
  end
end

-- Run the cleanup processing on the results and kick another iteration
function endTest(results) 
    local num, total
    local done = {}
    
    -- Convert all of the results to a delta list
    for i = 1,#results do
        diff(results[i])
    end
    num = #results[1]
 
    -- Convert the deltas from all timers to an average   
    for i = 1,num do
        total = 0;
        
        for r = 1,#results do
            total = total + results[r][i]
        end
        
        local avgDelay = total / #results
        
        done[i] = { x=i, y=avgDelay }
    end
    
    local label = string.format("%d timers @ %dms", numTimers, delay)
    table.insert(allResults, { ["data"] = done, ["label"]= label })
    
    numTimers = numTimers * 2;
    
    if (numTimers <= maxTimers ) then
        startTest();
    else
        plot(allResults)
        --$.plot($("#results"), allResults, {yaxis: {max: 50}});
    end
end

-- Utility function to transform an array of measurements to an array
-- of deltas (reducing the total array length by 1)
function diff( data ) 
    for i = 1,#data-1 do
        data[i] = data[i+1] - data[i]
    end
    
    table.remove(data)

    return data;
end

-- Plot out the value of the allResults array
function plot(finalResults) 
  plotCSV(finalResults)  
  plotChart(finalResults)
end

function plotCSV(finalResults) 
  for r=1,#finalResults do
    local csvTable = {}

    local entry = allResults[r]
    table.insert(csvTable, entry.label)

    local data = entry.data
    for d=1,#data do
      table.insert(csvTable, tostring(data[d].y)) 
    end
    print(table.concat(csvTable,","))
  end
end

function plotChart(finalResults)

end

-- Establish all of the controls that are going to be drawing
function createControls() 
  -- TODO: This isn't done by the JS version, so we skip it for now
  if(true) then
    return
  end
  
  local baseLayer = "TestLayer"
  local baseControl = "TestLayer.dot1"
  local cInfo = gre.get_control_attrs(baseControl, "width", "height", "y")
  
  for i=2,maxTimers do
    local newName = string.format("dot%d", i)
    cInfo.y = cInfo.y + cInfo.height + 2  --Offset new position by 2px
    gre.clone_control(baseControl,newName,baseLayer, cInfo)      
  end
end

function CBStartTest(mapargs) 
  print("Starting Test!")
  createControls()
  startTest()
end
