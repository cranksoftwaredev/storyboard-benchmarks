This is a benchmark test adapted Storyboard from the baseline FramerateTest
which itself is a test adapted from the HTML/JS test:
  http://www.craftymind.com/guimark/
 

This new benchmark was adjusted to cycle extended text (ie non-latin) through the 
test to gauge the difference in performance.  This test cycles latin, cyrilic and 
chinese text through in both shaped and unshaped scenarios.

The original FramerateTest was also driven by a 20ms timer which capped the
perfomance at 50 FPS

Nov 11 2020 Crank TZ
FramerateTestIntl does the following on loop:
    calculateFramerate()
    tweenValues()
    executeBindings()
calculateFramerate increments a local sampleFramerate counter on each call, and resets after detecting 500ms elapsed. The problem is that tweenValues makes calculations based on the value of getTimer (which returns gre.mstime(true)). It is possible that on subsequent iterations of the loop that getTimer returns the same value -- in which case sampleFramerate increments but tweenValues does no work. This causes a positive feedback loop. tweenValues doing no work causes us to re-enter the loop faster which causes the subsequent getTimer value to have a lower chance of changing. And getTimer values not channging causes tweenValues to do no work.

An issue that was uncovered during the examination of the test was that gre.ustime was not incrementing time at the microsecond granularity (only showing numbers in multiple of thousands). This could potentially affect the result of gre.mstime in such a way that affects the likelihood of it reporting the same value on subsequent iterations of the loop.

While this doesn't explain the exact cause of the dip and rise in win32 software numbers for this test, it does highlight that the test is sensitive to changes to the value of gre.mstime(). This test was modified to only do work when a "time" has changed on subsequent entries of the timer cb.
