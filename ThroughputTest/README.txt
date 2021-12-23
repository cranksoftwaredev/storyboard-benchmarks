This is a simple throughput test that measures the operation 
time for a few operations.  Unless otherwise noted, each operation
is performed 1000 times to get an average value.

Test 1: LuaEvent 
- Given no data changes, how fast can an event be generated
from a lua script and received back into a lua script.  The
average time is measured from:
Lua Script gre.send_event -> Lua Script action handler

Test 2: FillDataChangeEvent
- How fast can an data change be processed by the system.
This test changes a single data variable (fill colour) and
generates an event, which should serialize into a screen
update event (as a result of the data change) and the custom
event delivery.  
Single Variable gre.set_data, 
Lua Script gre.send_event ->
Lua Script action handler 

Test 3: MultiFillDataChangeEvent
- How fast can multiple data changes be processed by the system.
This test changes multiple data variables (fill colour) and
generates an event, which should serialize into a screen
update event (as a result of the data change) and the custom
event delivery.  
Single Variable gre.set_data, 
Lua Script gre.send_event ->
Lua Script action handler 

Test 4: JPEGDataChangeEvent
- How fast can a single data changes be processed by the system.
This test changes a single data variable (jpeg image) and
generates an event, which should serialize into a screen
update event (as a result of the data change) and the custom
event delivery.  
The JPEG is an unscaled image
Single Variable gre.set_data, 
Lua Script gre.send_event ->
Lua Script action handler 

Test 5: MultiJPEGDataChangeEvent
- How fast can a multiple data changes be processed by the system.
This test changes a multiple data variables (jpeg image) and
generates an event, which should serialize into a screen
update event (as a result of the data change) and the custom
event delivery.  
The JPEG is an scaled image
Single Variable gre.set_data, 
Lua Script gre.send_event ->
Lua Script action handler 


