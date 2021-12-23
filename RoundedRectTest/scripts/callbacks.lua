--- @param gre#context mapargs
local function lerp(a, b, t)
  return a + ((b - a) * t)
end

local function unlerp(a, b, c)
  return (c - a) / (b - a)
end

local t = 0
local direction = 1
local max_arc = 60
local min_arc = 60
function CBArcChange(mapargs) 
  local data = {}
  --data['Content.Fill.aw'] = lerp(0, max_arc, t)
  --data['Content.Fill.ah'] = lerp(0, max_arc, 1.0 - t)
  local attrs = {}
  attrs.y = lerp(0, 480 - 240, t)
  attrs.x = lerp(0, 800 - 240, ((1 + math.cos(lerp(0, 2 * math.pi, t))) / 2))
  t = t + (direction * 0.01)
  if t >= 1.0 and direction == 1 then
    direction = -1
  end
  if t <= 0.0 and direction == -1 then
    direction = 1
  end
  gre.set_data(data)
  gre.set_control_attrs('Content.Fill', attrs)
end

local arcs_set = false
function CBStretch(mapargs)
  local attrs = {}
  if(not arcs_set) then
    local data = {}
    --data['Content.Fill.aw'] = max_arc
    --data['Content.Fill.ah'] = max_arc
    gre.set_data(data)
    arcs_set = true
    attrs.x = 0
    attrs.y = 0
  end
  attrs.height = math.floor(lerp(min_arc * 2 + 1, 480, t))
  attrs.width = math.floor(lerp(min_arc * 2 + 1, 800, ((1 + math.cos(lerp(0, 2 * math.pi, t))) / 2)))
  t = t + (direction * 0.01)
  if t >= 1.0 and direction == 1 then
    direction = -1
  end
  if t <= 0.0 and direction == -1 then
    direction = 1
  end

  --CRANK TF: SB-9854 Remove double precision temporarily
  attrs.height = math.floor(attrs.height)
  attrs.width = math.floor(attrs.width)
  gre.set_control_attrs('Content.Fill', attrs)
end



