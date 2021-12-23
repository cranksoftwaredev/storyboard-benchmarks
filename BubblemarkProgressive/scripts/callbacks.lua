--[[
Copyright 2012, Crank Software Inc.
All Rights Reserved.
For more information email info@cranksoftware.com
** FOR DEMO PURPOSES ONLY **
]]

-- Call back functions for the BubbleMark benchmark test

-- This controls the runtime behaviour of this test.  The original JS version
-- runs on a fixed timer, but that means that the test is artificially
-- limited in its framerate.  By making the test entirely event driven (draw
-- a frame, trigger next frame) we make the test scale up/down more appropriately.
-- events_instead_of_timers ==> TRUE makes the test purely event driven
-- events_instead_of_timers ==> FALSE makes the test run at the timer rate
local events_instead_of_timers = true
local MS_TIME_THRESH = 2 * 1000
local MAX_ITERS = 1
local MAX_BALLS = 256
local numBalls = 2
local numFrames = 0
local numIters = 0
local firstFrameTime = nil
local moveTime = 0

-- Seed the random number generator with a consistent value, set to nil for really random
local RNGSeed = 1
if(RNGSeed == nil) then
  RNGSeed = gre.mstime()
end
math.randomseed(RNGSeed)

require("BallsTest")


-- Utility functions for the performance metrics

-- Inline mapping of the time function in case it is missing
if(not gre.mstime) then
  print("WARN: Missing mstime, simulating with os.clock() * 1000")
  gre.mstime = function() 
    return os.clock() * 1000
  end
end

-- Simple performance log print out wrapper
if(not gre.log_perf_stat) then
  gre.log_perf_stat = function(test, qualifier, result, description)
    print("PERF: " .. test .. ", " .. qualifier .. ", " .. tostring(result) .. ", " .. description);
  end
end


-- Our root control object
local ballsTest


-- Initialize the test with 2 balls
function cb_init(mapargs)
	--print("Init Balls Test")
  ballsTest = BallsTest:init(numBalls)
	ballsTest:start()
	
	-- Hide the reference ball
	gre.set_control_attrs("main_layer.ball", { hidden = 1 })
end


function cb_start_frame(mapargs)
		gre.send_event("next_frame")
end

function cb_move(mapargs)
  local start = gre.mstime()
  _cb_move(mapargs)
  moveTime = moveTime + (gre.mstime() - start)
end

function _cb_move(mapargs)
  local now = gre.mstime()
  
	--print("Move Balls")
	numFrames = numFrames + 1	
	if (numFrames == 1) then
	   firstFrameTime = now
  elseif ((now - firstFrameTime) > MS_TIME_THRESH) then
      local fps = ((numFrames-1) * 1000) / (now - firstFrameTime)
	    if (numIters == 0) then
          gre.log_perf_stat("BubblemarkProgressive", numBalls.." balls", fps, "fps")
          gre.log_perf_stat("BubblemarkProgressive", numBalls.." lua", moveTime / numFrames, "ms")
          ballsTest:showFPS()
      end

      ballsTest:stop()

      numBalls = numBalls * 2
      if (numBalls > MAX_BALLS) then
          numBalls = 2
          numIters = numIters + 1
          if (numIters >= MAX_ITERS) then
              gre.send_event("gre.quit")            
          end
      end
      numFrames = 0      
      moveTime = 0
     
      ballsTest = BallsTest:init(numBalls)          
      ballsTest:start()      
	else
      ballsTest:moveBalls()
  end
 
	gre.send_event("next_frame")
end

