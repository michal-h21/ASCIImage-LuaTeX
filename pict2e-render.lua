local function render(image)
  local lines =  {}
  local objects = image.objects or {}
  local function add_object(what)
    lines[#lines+1] = what
  end
  local function prepare_points(obj)
    local points = {}
    for _, point in ipairs(obj.points) do
      points[#points+1] = point[1] .. ","..point[2]
    end
    return points
  end

  for _,object in ipairs(objects) do
    local typ = object.type
    local points = prepare_points(object)
    if typ == "poly" then
      add_object('\\polygon*' .. '(' .. table.concat(points, ')(') .. ')')
      -- elseif typ == "line" then
    end
  end
  return table.concat(lines, "\n")
end

return render
