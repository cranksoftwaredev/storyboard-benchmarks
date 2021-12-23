This is a benchmark test adapted to Storyboard from:

http://www.craftymind.com/guimark/
 
The port was done using the HTML version and changing the JS to Lua

This test is rate limited to 20ms (50FPS) because it uses a timer to trigger
the redrawing of the frames.  For a purely event driven test, use the 
FrameRateTestIntl.
