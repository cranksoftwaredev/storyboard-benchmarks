
-- Adopted from the JS Vector Charting Test version at
-- http://www.craftymind.com/guimark2/

-- By default we run as a purely event driven activity.  If this flag is
-- changed to false, then we will run as a timer based application which 
-- doesn't scale as well for high to low end platforms.
local runEventBased = true
local perfLogMSDelay = 3000
local quitAfterPerf = true

-- Seed the random number generator with a consistent value, set to nil for really random
local RNGSeed = 1
if(RNGSeed == nil) then
  RNGSeed = gre.mstime()
end
math.randomseed(RNGSeed)

chartWidth = 1200
chartHeight = 600
highestStock = 200
totalMinutes = 480
chartXSpread = 0
chartYSpread = 0
a = {}
b = {};
c = {};
d = {};
e = {};

poly_varnames = {}
poly_varnames[a] = "l_chart.c_canvas.a" 
poly_varnames[b] = "l_chart.c_canvas.b" 
poly_varnames[c] = "l_chart.c_canvas.c" 
poly_varnames[d] = "l_chart.c_canvas.d" 
poly_varnames[e] = "l_chart.c_canvas.e"

function init()
	--var canvas = document.getElementById('canvas');
	--draw = canvas.getContext('2d');
	chartXSpread = chartWidth/totalMinutes;
	chartYSpread = chartHeight/highestStock;
	meter = FPSMeter.create();
	--fps = document.getElementById("current");
	--results = document.getElementById("results");
	--setInterval("processFrame()", 17);
	if(runEventBased) then
		gre.send_event("timer.frame_timer")
	else
		gre.send_event("frame_timer_start")
	end
end
 
function processFrame()
	--draw.clearRect(0,0,chartWidth,chartHeight);
	--draw.beginPath();
	--draw.lineWidth = 1;
	--draw.strokeStyle = "#666666";
 
	local xCoord
	local yCoord
	local x,y
	-- Draw the grid
	for x=0,totalMinutes,40 do
		xCoord = x*chartXSpread+0.5
		--draw.moveTo(xCoord, 0)
		--draw.lineTo(xCoord, chartHeight)
	end
	for y=0,highestStock,20 do
		yCoord = y*chartYSpread+0.5
		--draw.moveTo(0, yCoord);
		--draw.lineTo(chartWidth, yCoord);
	end
	--draw.stroke();
	--draw.closePath();
 
	fillStockData(a, 180)
	fillStockData(b, 140)
	fillStockData(c, 100)
	fillStockData(d, 60)
	fillStockData(e, 20)
 
	graphStockData(a, b, "#FF00FF", "rgba(255, 176, 255, 0.6)")
	graphStockData(b, c, "#FF0000", "rgba(255, 176, 176, 0.6)")
	graphStockData(c, d, "#FF6600", "rgba(255, 216, 176, 0.6)")
	graphStockData(d, e, "#0000FF", "rgba(176, 176, 255, 0.6)")
	graphStockData(e, null, "#00FF00", "rgba(176, 255, 176, 0.6)")
	
	updatePerformance();
	
	if(runEventBased) then
		gre.send_event("timer.frame_timer")
	end   
end
 
function fillStockData(data, region)
	local diff = 15;
	local low = region-(diff/2);
	local i = 1;
	local stock;
	
	if(#data == 0) then
		while(i <= totalMinutes) do
			stock = StockVO.create(i, math.random()*diff+low)
			table.insert(data, stock)
			i = i + 1
		end
	else
		while(i <= totalMinutes) do
			stock = data[i]
			stock.minute = stock.minute - 1
			i = i + 1
		end
		stock = table.remove(data, 1)
		stock.minute = totalMinutes
		stock.value = math.random()*diff+low
		table.insert(data, stock)
	end
end

local function make_string_coord(x, y)
	return string.format("%d:%d", x, y)
end
 
-- Line and fill are ignored, they are set in Designer
function graphStockData(topData, bottomData, line, fill) 
	local stock;
	local xCoord;
	local yCoord;
	local i = 1;
	
	--draw.beginPath();
	--draw.strokeStyle = line;
	--draw.lineWidth = 2;
	--draw.lineCap = "round";
	--draw.lineJoin = "round";
	--draw.fillStyle = fill;
 
	stock = topData[i];
	xCoord = stock.minute*chartXSpread;
	yCoord = chartHeight-stock.value*chartYSpread;
	
	-- Save to loop back
	local startx = xCoord;
	local starty = yCoord;

	xPoints = {}
	yPoints = {}
	table.insert(xPoints, xCoord)
	table.insert(yPoints, yCoord)

	--draw.moveTo(xCoord, yCoord);
 
	while(i < #topData) do
		i = i + 1
		stock = topData[i]
		xCoord = stock.minute*chartXSpread
		yCoord = chartHeight-stock.value*chartYSpread
		
		table.insert(xPoints, xCoord)
		table.insert(yPoints, yCoord)
	
		--draw.lineTo(xCoord, yCoord);
	end
	--draw.stroke();
	
	if(bottomData ~= nil) then
		i = #bottomData + 1
		while(i > 1) do
			i = i - 1
			stock = bottomData[i]
			xCoord = stock.minute*chartXSpread
			yCoord = chartHeight-stock.value*chartYSpread
			
			table.insert(xPoints, xCoord)
			table.insert(yPoints, yCoord)
			
			--draw.lineTo(xCoord, yCoord);
		end
	else
		table.insert(xPoints, chartWidth)
		table.insert(yPoints, chartHeight)
		--draw.lineTo(chartWidth, chartHeight);
		
		table.insert(xPoints, 0)
    table.insert(yPoints, chartHeight)
		--draw.lineTo(0, chartHeight);
		
		--table.insert(xPoints, 0)
    --table.insert(yPoints, chartHeight)
		--draw.lineTo(0, chartHeight);ble.insert(yPoints, chartHeight)		
	end
	
	table.insert(xPoints, startx)
	table.insert(yPoints, starty)
	
	--draw.fill();
	--draw.closePath();
	
	local varname = poly_varnames[topData]

	local dv = {}
	dv[varname] = gre.poly_string(xPoints, yPoints)
	gre.set_data(dv)
end
 
local startTime 
function updatePerformance()
	if(startTime == nil) then
		startTime = gre.mstime()
	end

	meter:increment();
	
	local fps = meter:getFramerate();
	
	local dv = {}
	dv["l_chart.c_current.txt"] = "Current: " .. tostring(fps) .. " fps"
	gre.set_data(dv)
	
	-- Generate our FPS performance log number after 
	if((perfLogMSDelay ~= 0) and (gre.mstime() - startTime) > perfLogMSDelay) then
		gre.log_perf_stat("ChartingTest", "ChartingTest", fps, "fps")
		perfLogMSDelay = 0
				
		if(quitAfterPerf == true) then
			gre.send_event("gre.quit")
		end
	end
	
	--fps.innerHTML = "Current: "+meter.getFramerate()+" fps";
	--if(testRunning) then
	--	continueTest();
	--end
end
 
-- test runner
--[[
var testBegin = 0;
var testData = [];
var testRunning = false;
function startTest(){
	testBegin = TimeUtil.getTimer();
	testRunning = true;
	testData = [];
	results.innerHTML = "Running..."
}
function continueTest(){
	var time = TimeUtil.getTimer();
	testData.push(time);
	if(time-testBegin > 10000){
		testRunning = false;
		var output = testData.length/(time-testBegin)*1000;
		results.innerHTML = "Test Average: "+FPSMeter.formatNumber(output)+" fps"
	}
}
]]
 
--additional classes
StockVO = {}
StockVO.__index = StockVO

function StockVO.create(minute, value) 
	local v = {}
	setmetatable(v, StockVO)
	v.minute = minute
	v.value = value
	return v
end
 
FPSMeter = {}
FPSMeter.__index = FPSMeter

function FPSMeter.create()
	local v = {}
	setmetatable(v, FPSMeter)
	
	v.sampleFPS = 0;
	v.lastSampledTime = 0;
	v.sampleFrames = 0;
	v.sampleDuration = 2000;
	
	return v
end

function FPSMeter:increment()
	self.sampleFrames = self.sampleFrames + 1;
end

function FPSMeter:getFramerate()
	local diff = TimeUtil.getTimer()- self.lastSampledTime;
	if(diff >= self.sampleDuration) then				-- Recalculate every 500ms
		local rawFPS = self.sampleFrames/(diff/1000);
		self.sampleFPS = FPSMeter_formatNumber(rawFPS);
		self.sampleFrames = 0;
		self.lastSampledTime = TimeUtil.getTimer();
	end
	
	return self.sampleFPS;
end

function FPSMeter_formatNumber(val)
	--format as XX.XX
	return math.floor(val*100)/100;
end
 
TimeUtil = {}
TimeUtil.startTime = gre.mstime()
TimeUtil.getTimer = function() 
	return gre.mstime() - TimeUtil.startTime
end

--[[ 

<!DOCTYPE html> 
<html> 
<head> 
<title>GUIMark 2 - HTML5 Vector Test</title> 
<meta http-equiv="content-type" content="text/html; charset=UTF-8"> 
<script type="text/javascript"> 
var meter;
var fps;
var results;
var draw;
 
var chartWidth = 1201;
var chartHeight = 600;
var highestStock = 200;
var totalMinutes = 480;
var chartXSpread;
var chartYSpread;
var a = new Array();
var b = new Array();
var c = new Array();
var d = new Array();
var e = new Array();
 
function init(){
	var canvas = document.getElementById('canvas');
	draw = canvas.getContext('2d');
	chartXSpread = chartWidth/totalMinutes;
	chartYSpread = chartHeight/highestStock;
	meter = new FPSMeter();
	fps = document.getElementById("current");
	results = document.getElementById("results");
	setInterval("processFrame()", 17);
}
 
function processFrame(){
	draw.clearRect(0,0,chartWidth,chartHeight);
	draw.beginPath();
	draw.lineWidth = 1;
	draw.strokeStyle = "#666666";
 
	var xCoord;
	var yCoord;
	for(var x=0; x<=totalMinutes; x+=40){
		xCoord = x*chartXSpread+0.5;
		draw.moveTo(xCoord, 0);
		draw.lineTo(xCoord, chartHeight);
	}
	for(var y=0; y<=highestStock; y+=20){
		yCoord = y*chartYSpread+0.5;
		draw.moveTo(0, yCoord);
		draw.lineTo(chartWidth, yCoord);
	}
	draw.stroke();
	draw.closePath();
 
	fillStockData(a, 180);
	fillStockData(b, 140);
	fillStockData(c, 100);
	fillStockData(d, 60);
	fillStockData(e, 20);
 
	graphStockData(a, b, "#FF00FF", "rgba(255, 176, 255, 0.6)");
	graphStockData(b, c, "#FF0000", "rgba(255, 176, 176, 0.6)");
	graphStockData(c, d, "#FF6600", "rgba(255, 216, 176, 0.6)");
	graphStockData(d, e, "#0000FF", "rgba(176, 176, 255, 0.6)");
	graphStockData(e, null, "#00FF00", "rgba(176, 255, 176, 0.6)");
	
	updatePerformance();
}
 
function fillStockData(data, region){
	var diff = 15;
	var low = region-(diff/2);
	var i = 0;
	var stock;
	
	if(data.length == 0){
		while(i <= totalMinutes){
			stock = new StockVO(i, Math.random()*diff+low);
			data.push(stock);
			i++;
		}
	}else{
		while(i <= totalMinutes){
			stock = data[i];
			stock.minute--;
			i++;
		}
		stock = data.shift();
		stock.minute = totalMinutes;
		stock.value = Math.random()*diff+low;
		data.push(stock);
	}
}
 
function graphStockData(topData, bottomData, line, fill){
	var stock;
	var xCoord;
	var yCoord;
	var i = 0;
	
	draw.beginPath();
	draw.strokeStyle = line;
	draw.lineWidth = 2;
	draw.lineCap = "round";
	draw.lineJoin = "round";
	draw.fillStyle = fill;
 
	stock = topData[i];
	xCoord = stock.minute*chartXSpread;
	yCoord = chartHeight-stock.value*chartYSpread;
	draw.moveTo(xCoord, yCoord);
 
	while(++i < topData.length){
		stock = topData[i];
		xCoord = stock.minute*chartXSpread;
		yCoord = chartHeight-stock.value*chartYSpread;
		draw.lineTo(xCoord, yCoord);
	}
	draw.stroke();
	
	if(bottomData != null){
		i = bottomData.length;
		while(--i > -1){
			stock = bottomData[i];
			xCoord = stock.minute*chartXSpread;
			yCoord = chartHeight-stock.value*chartYSpread;
			draw.lineTo(xCoord, yCoord);
		}
	}else{
		draw.lineTo(chartWidth, chartHeight);
		draw.lineTo(0, chartHeight);
	}
	draw.fill();
	draw.closePath();
}
 
function updatePerformance(){
	meter.increment();
	fps.innerHTML = "Current: "+meter.getFramerate()+" fps";
	if(testRunning){
		continueTest();
	}
}
 
//test runner
var testBegin = 0;
var testData = [];
var testRunning = false;
function startTest(){
	testBegin = TimeUtil.getTimer();
	testRunning = true;
	testData = [];
	results.innerHTML = "Running..."
}
function continueTest(){
	var time = TimeUtil.getTimer();
	testData.push(time);
	if(time-testBegin > 10000){
		testRunning = false;
		var output = testData.length/(time-testBegin)*1000;
		results.innerHTML = "Test Average: "+FPSMeter.formatNumber(output)+" fps"
	}
}
 
//additional classes
function StockVO(minute, value){
	this.minute = minute;
	this.value = value;
}
 
function FPSMeter(){
	var sampleFPS = 0;
	var lastSampledTime = 0;
	var sampleFrames = 0;
	
	this.sampleDuration = 500;
	this.increment = function(){
		sampleFrames++;
	}
	this.getFramerate = function(){
		var diff = TimeUtil.getTimer()-lastSampledTime;
		if(diff >= this.sampleDuration){
			var rawFPS = sampleFrames/(diff/1000);
			sampleFPS = FPSMeter.formatNumber(rawFPS);
			sampleFrames = 0;
			lastSampledTime = TimeUtil.getTimer();
		}
		return sampleFPS;
	}
}
FPSMeter.formatNumber = function(val){
	//format as XX.XX
	return Math.floor(val*100)/100;
}
 
TimeUtil = {
	startTime: new Date().getTime(),
	getTimer: function(){
		return new Date().getTime()-TimeUtil.startTime;
	}
}
</script> 
<style type="text/css"> 
.header {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 15px;
	font-weight: bold;
	width: 1200px;
	height: 30px;
	background-color: #C0C4DF;
}
.header>div {
	padding: 6px;
	display: inline-block;
}
</style> 
</head> 
 
<body onload="init()" style="margin:0px;"> 
	<div class="header"> 
		<div style="width:300px">GUIMark - Vector Chart Test</div> 
		<div><input type="button" value="Start Test" onclick="startTest()"/></div> 
		<div id="current" style="width:140px">Current: 10 fps</div> 
		<div id="results"></div> 
	</div> 
	<canvas id="canvas" width="1200" height="600"></canvas> 
 
<script type="text/javascript"> 
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script> 
<script type="text/javascript"> 
try {
var pageTracker = _gat._getTracker("UA-15981974-1");
pageTracker._trackPageview();
} catch(err) {}</script> 
 
</body> 
</html>
]]
