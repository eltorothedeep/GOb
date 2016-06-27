local scene = composer.newScene()
 
---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------
 
-- local forward references should go here
 local canvasTop = appOriginY
 local header
 local optButtons = {}
---------------------------------------------------------------------------------

local optionTypes = 
{
	--{ "id", "Button Label", "screen", showAsOverlay },

	{ "Cancel", "Cancel", "welcomescreen", false },
	{ "Session", "Session Options", "sessionOpts", true },
	{ "Questions", "Question Options", "questionOpts", true },
	{ "Types", "Type Options", "typeOpts", true },
	{ "Continents", "Continent Options", "continentOpts", true },
	{ "Countries", "Country Options", "countryOpts", true },
	{ "Start", "Start Quiz", "quizscreen", false },
}

local function GetDBOptions( event )
	local optNum = 0
	for i=1,#optionTypes do
		if event.target.id == optionTypes[i][1] then
			optScreen = i
			break
		end
	end
	if optScreen > 0 then
		local options = {
			effect = "fade",
			time = 200,
			params = 
			{
				originY = canvasTop,
			},
			isModal = true
		}
		--print( "typeList: " .. tostring( composer.getVariable( "typeList" ) ) )
		if optionTypes[optScreen][4] then
			composer.showOverlay( optionTypes[optScreen][3], options )
		else
			composer.gotoScene( optionTypes[optScreen][3], options )
		end
	end
end
 
-- "scene:create()"
function scene:create( event )
 
   local sceneGroup = self.view
 
   -- Initialize the scene here.
   -- Example: add display objects to "sceneGroup", add touch listeners, etc.
   
   header, canvasTop = AddText( sceneGroup, "Geo Quiz", 24, 190/255, 190/255, 1, 1, _W/2, appOriginY, 0 );
   
	local buttonOptions = 
	{
		emboss = false,
		shape="roundedRect",
		anchorX = 0.5,
		width = _W*.8,
		cornerRadius = 10,
		labelColor = { default={ 1, 1, 1, 1 }, over={ .1, 0.1, 0.1, 1 } },
		fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
		strokeColor = { default=theme[4].Color, over={ 0, 0, 0, 1 } },
		strokeWidth = 5,	
		onRelease = GetDBOptions
	}
	local numSpots = 1 + #optionTypes * 2
	buttonOptions.height = ( display.contentHeight - canvasTop ) / numSpots

   	for i=1,#optionTypes do
	-- Button Specific Options
		buttonOptions.id = optionTypes[i][1]
		buttonOptions.label = optionTypes[i][2]
		-- Create and Add
		optButtons[i] = widget.newButton( buttonOptions )
		optButtons[i].x = display.contentWidth * 0.5
		optButtons[i].y = canvasTop + ( buttonOptions.height * i * 2 ) - ( buttonOptions.height / 2 )
		sceneGroup:insert( optButtons[i] )
	end
end
 
-- "scene:show()"
function scene:show( event )
 
   local sceneGroup = self.view
   local phase = event.phase
 
   if ( phase == "will" ) then
      -- Called when the scene is still off screen (but is about to come on screen).
   elseif ( phase == "did" ) then
      -- Called when the scene is now on screen.
      -- Insert code here to make the scene come alive.
      -- Example: start timers, begin animation, play audio, etc.
   end
end
 
-- "scene:hide()"
function scene:hide( event )
 
   local sceneGroup = self.view
   local phase = event.phase
 
   if ( phase == "will" ) then
      -- Called when the scene is on screen (but is about to go off screen).
      -- Insert code here to "pause" the scene.
      -- Example: stop timers, stop animation, stop audio, etc.
   elseif ( phase == "did" ) then
      -- Called immediately after scene goes off screen.
   end
end
 
-- "scene:destroy()"
function scene:destroy( event )
 
   local sceneGroup = self.view

   -- Called prior to the removal of scene's view ("sceneGroup").
   -- Insert code here to clean up the scene.
   -- Example: remove display objects, save state, etc.
   header:removeSelf()
   	for i=1,#optButtons do
		optButtons[i]:removeSelf()
	end
end
 
---------------------------------------------------------------------------------
 
-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
 
---------------------------------------------------------------------------------
 
return scene