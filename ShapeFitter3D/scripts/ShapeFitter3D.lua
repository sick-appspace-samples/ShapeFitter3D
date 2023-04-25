
--Start of Global Scope---------------------------------------------------------

local viewer = View.create()

-- Cyan color scheme for search regions
local regionDecoration = View.PixelRegionDecoration.create():setColor(0, 255, 255, 60)
local searchDecoration = View.ShapeDecoration.create():setFillColor(0, 255, 255, 80)
searchDecoration:setLineColor(0, 255, 255):setLineWidth(3)

-- Green color scheme for fitted lines and circles using ransac.
local foundDecoration = View.ShapeDecoration.create():setFillColor(0, 255, 0, 120)
foundDecoration:setLineColor(0, 255, 0):setLineWidth(5):setPointSize(9)

-- Create shape fitters. Set fit mode to RANSAC to be robust
-- against outliers. In this case, lines are fitted to distinct edges
-- while circles are fitted to rounded edges. Use two different
-- shape fitters with different parameters.

local sfLine = Image.ShapeFitter.create()
sfLine:setFitMode('RANSAC')
local sfCircle = Image.ShapeFitter.create()
sfCircle:setFitMode('RANSAC')
sfCircle:setDifferenceStep(3)
sfCircle:setSelection('LAST')
sfCircle:setThreshold(0.4)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

---@param hm Image
---@param box Shape3D
---@return Shape3D
---@return Shape3D
local function findHighLowLines(hm, box)
  local boxRegion, boxMinZ, boxMaxZ = box:toPixelRegion(hm)

  -- Find line at the top of the discontinuity, edge is mainly oriented along
  -- the x-axis.
  sfLine:setSide('HIGH')
  local highLine =  sfLine:fitLine3D(hm, boxRegion, {boxMinZ, boxMaxZ}, 3.1415 / 2)

  sfLine:setSide('LOW')
  local lowLine = sfLine:fitLine3D(hm, boxRegion, {boxMinZ, boxMaxZ}, 3.1415 / 2)

  return highLine, lowLine
end

---@param hm Image
---@param cylinder Shape3D
---@param innerRadius float
---@return Shape3D
local function findHighCircle(hm, cylinder, innerRadius)
  -- Extract fitting area from cylinder.
  -- The cylinder is expected to have its symmetry axis aligned with the z-axis.
  local radius, height, _ = cylinder:getCylinderParameters()
  local center = cylinder:getCenterOfGravity()
  local searchCircle = Shape.createCircle(Point.create(center:getXY()), radius)
  local minZ = center:getZ() - height / 2
  local maxZ = center:getZ() + height / 2

  -- Find circle at the top of the discontinuity.
  sfCircle:setSide('HIGH')
  local fittedCircle = sfCircle:fitCircle3D(hm, searchCircle, innerRadius, {minZ, maxZ})

  return fittedCircle
end

local function main()
  -- Loading heightmap from resources.
  local images = Object.load('resources/image.json')
  local heightmap = images[1]
  local intensitymap = images[2]

  -- Define search area boxes for the tilted planes.
  local searchCyl1 = Shape3D.createCylinder(7, 30, Transform.createTranslation3D(-36, 86, 125))
  local searchBox2 = Shape3D.createBox(35, 10, 45, Transform.createTranslation3D(-38, 108, 130))

  -- Fit lines and circles
  local circle1 = findHighCircle(heightmap, searchCyl1, 3)
  local highLine, lowLine = findHighLowLines(heightmap, searchBox2)

  -- Show fitting results
  viewer:clear()
  local imgDecoration = View.ImageDecoration.create()
  imgDecoration:setRange(100.0, 120.0)
  local hmViewId = viewer:addHeightmap({heightmap, intensitymap}, imgDecoration, {'Reflectance'})

  viewer:addShape(searchCyl1, searchDecoration, nil, hmViewId)
  viewer:addShape(circle1, foundDecoration, nil, hmViewId)

  viewer:addShape(searchBox2, searchDecoration, nil, hmViewId)

  viewer:addShape(highLine, foundDecoration, nil, hmViewId)
  viewer:addShape(lowLine, foundDecoration, nil, hmViewId)
  viewer:present()

  print('App finished.')
end

--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
