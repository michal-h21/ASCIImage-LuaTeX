-- Lua port of https://github.com/cparnot/ASCIImage
local asciimage = {}

-- only following characters are taken into account in the drawing
local allowed = "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz"
-- table for lookup whether the char is allowed
local allowed_chars = {}
-- table for traversing the allowed characters in correct order 
local allowed_sequence = {}

for i = 1, string.len(allowed) do
  local char = string.sub(allowed, i, i) 
  allowed_chars[char] = true
  allowed_sequence[i] = char
end

-- we must match Unicode chars
local ugmatch = unicode.utf8.gmatch

local function parse_line(line)
  local characters = {}
  -- match all characters which aren't spaces
  for character in ugmatch(line,"([^%s])") do
    characters[#characters+1] = character
  end
  -- print(table.concat(characters, "."))
  return characters
end

local function print_objects(objects)
  for _, obj in ipairs(objects) do
    local points = {}
    for _, point in ipairs(obj.points) do
      points[#points+1] = point[1] .. ","..point[2]
    end
    print(obj.type, "(".. table.concat(points,"), (").. ")" )
  end
end

local function get_tokens(grid)
  local tokens = {}
  for y = 1, #grid do
    local line = grid[y]
    for x = 1,#line do
      local char = line[x]
      if allowed_chars[char] then
        -- we need to count appearance of the character. it may appear once
        -- (polygon or point), twice (line), or more than twice (ellipse)
        local token = tokens[char] or {}
        token[#token+1] = {x,y}
        tokens[char] = token
      end
    end
  end
  return tokens
end

local function get_objects(tokens)
  local objects = {}
  local current_object
  local insert_current = function()
    -- current_object can be nil, it is OK
    objects[#objects+1] = current_object 
    current_object = nil
  end
  local make_current = function(typ, obj)
    -- set current object type and add points 
    current_object = current_object or {}
    current_object.type = typ
    -- it should exist only in the case of polylines
    local points = current_object.points or {}
    for _, new_points in ipairs(obj) do
      points[#points + 1] = new_points
    end
    current_object.points = points
  end
  for _, char in ipairs(allowed_sequence) do
    local obj = tokens[char]
    if not obj then 
      -- if current object is empty, we must stop any previous polygon objects
      insert_current()
    elseif #obj == 2 then
      insert_current()          -- lines and ellipses are standalone objects, we must
      make_current("line", obj) -- close previous objects and then insert them immediatelly
      insert_current()
    elseif #obj > 2 then
      insert_current()
      make_current("ellipse", obj)
      insert_current()
    else
      if current_object then
        make_current("poly", obj) -- if the current_object exists, it must be a polygon
      else
        make_current("point", obj) -- always start polygon as a point
      end
    end
  end
  insert_current()
  return objects
end

local function parse_objects(grid)
  local tokens = get_tokens(grid)
  local objects = get_objects(tokens)
  return objects
end

-- parse array with lines
function asciimage.parse(lines)
  local image = {}
  local lines = lines or {}
  image.height = #lines
  local grid = {}
  local width 
  for _, line in ipairs(lines) do
    grid[#grid+1] = parse_line(line)
  end
  image.width = #grid[1]
  image.objects = parse_objects(grid)
  return image
end




local test = [[
· · · 1 2 · · · · · 
· r · A # # · · · · 
· # · · # # # · · · 
· # · · · # # # · · 
· r · · · · 9 # 3 · 
· · · s · · 8 # 4 · 
c · N · · # # # · · 
· · · · # # # · · · 
c · c 7 # # · · · · 
· · · 6 5 · · · · · 
]]

local lines = {}

for line in test:gmatch("([^\n]+)") do
  lines[#lines+1]= line
end
local image = asciimage.parse(lines)
print_objects(image.objects)

return asciimage

