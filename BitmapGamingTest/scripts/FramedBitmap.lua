
module("FramedBitmap", package.seeall)

function FramedBitmap:new(SourceArray) 
	local newFramedBitmap = {}
	setmetatable(newFramedBitmap, self)
	self.__index = self

	newFramedBitmap.bitmaps = {}
	newFramedBitmap.bitmaps = SourceArray
	
	newFramedBitmap.frame = 1
	
	return newFramedBitmap
end

	
function FramedBitmap:increment ()
	if(not self) then
		print("I'm not an object");
		return false
	end
	
	self.frame = self.frame + 1
	if(self.frame > table.maxn(self.bitmaps)) then
		self.frame = 1;
	end
end
	
function FramedBitmap:randomize ()
	if(not self) then
		print("I'm not an object");
		return false
	end
	
	self.frame = math.floor(math.random()*table.maxn(self.bitmaps));
end
	
function FramedBitmap:getBitmap ()
	if(not self) then
		print("I'm not an object");
		return false
	end
	
	
	
	return self.bitmaps[self.frame]
end
	
function FramedBitmap:getNextBitmap ()
	if(not self) then
		print("I'm not an object");
		return false
	end
	
	self.increment()
	return self.getBitmap()
end


