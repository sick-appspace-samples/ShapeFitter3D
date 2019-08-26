--[[----------------------------------------------------------------------------

  Application Name:
  ShapeFitter3D

  Summary:
  Fitting lines and circles in 3D to heightmap edges

  Description:
  This Sample shows how to use a ShapeFitter to fit circles and lines to edges
  in heightmaps. The results are visualized in the 3D viewer.

  How to Run:
  Starting this sample is possible either by running the app (F5) or
  debugging (F7+F10). Setting breakpoint on the first row inside the 'main'
  function allows debugging step-by-step after 'Engine.OnStarted' event.
  Results can be seen in the 3D viewer on the DevicePage.
  Select Reflectance in the View: box at the top of the GUI and zoom in on the
  data for best experience.
  Restarting the Sample may be necessary to show heightmap after loading the webpage.
  To run this Sample a device with SICK Algorithm API and AppEngine >= V2.5.0 is
  required. For example SIM4000 with latest firmware. Alternatively the Emulator
  in AppStudio 2.3 or higher can be used.

  More Information:
  Tutorial "Algorithms - Fitting and Measurement".

------------------------------------------------------------------------------]]

--Start of Global Scope---------------------------------------------------------

local viewer = View.create()

-- Cyan color scheme for search regions
local regionDecoration = View.PixelRegionDecoration.create()
regionDecoration:setColor(0, 255, 255, 60)
local searchDecoration = View.ShapeDecoration.create()
searchDecoration:setFillColor(0, 255, 255, 80)
searchDecoration:setLineColor(0, 255, 255)
searchDecoration:setLineWidth(3)

-- Green color scheme for fitted lines and circles using ransac.
local foundDecoration = View.ShapeDecoration.create()
foundDecoration:setFillColor(0, 255, 0, 120)
foundDecoration:setLineColor(0, 255, 0)
foundDecoration:setLineWidth(5)
foundDecoration:setPointSize(9)

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

--@findHighLowLines(hm:Image, box:Shape3D) : Shape3D, Shape3D
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

--@findHighCircle(hm:Image, cylinder:Shape3D, innerRadius:float) : Shape3d
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
