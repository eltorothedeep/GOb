local scene = composer.newScene()

local switchButtons = {}
local optHeader
local optText
local doneButton
local scrollView = nil
local scrollViewBackground = nil

local canvasTop

local compVarName = "countryList"

local tOpts = 
{
	--{ id, "switch type", initState, left, "composerVarName" },

	{ "ANY", "radio", 50, "countryAny" },
	{ "Select Types", "radio", 50, "countrySel"  },
	{ "US", "checkbox", 100, "countryList"  },
	{ "Other", "checkbox", 100, "countryList"  },
}

local function QOptionsDone( event )
	composer.hideOverlay( "typeOpts", 200 )
end

local function onSwitchPress( event )
	for i=1, #switchButtons do
		if event.target == switchButtons[i].button then
			if tOpts[i][2] == "radio" then
				-- Turn off/on check boxes based on radio buttons
				local alpha = 1
				if event.target.id == "ANY" then
					alpha = 0
				end
				
				for j=1, #switchButtons do
					if tOpts[j][2] ~= "radio" then
						switchButtons[j].button.alpha = alpha
						switchButtons[j].text.alpha = alpha + 0.5
					end
				end
			end
			-- Done for this button
			break
		end
	end
end

function scene:create( event )
    local sceneGroup = self.view
	local options =
	{
		parent = sceneGroup,
		x = 0,
		y = event.params.originY, 
		w = display.actualContentWidth, 
		h = display.actualContentHeight-event.params.originY, 
		anchorX = 0,
		anchorY = 0,
		fontsize = 18,
		fill  = 
		{
			type = 'gradient',
			color1 = { 1, 1, 1, 1 }, 
			color2 = { .8, .8, .8, 1 },
			direction = "up"
		}
	}	
	AddBackground( options )	
	optHeader, canvasTop = AddText( sceneGroup, "Continent Options", 20, 0, 0, 0, 1, _W/2.0, event.params.originY+15, 10 )
	optText, canvasTop = AddText( sceneGroup, "Ask About Which Continents", 16, 0, 0, 0, 1, _W/2.0, canvasTop, 0 )

	local radioGroup = display.newGroup()	
	sceneGroup:insert( radioGroup )
	
	local sqlcmd = 'select * from Countries'
	local dbInfo = GetQuizDBInfo( sqlcmd, 'Name' );
	for i= 1, #dbInfo do
		local entry = { dbInfo[i], "checkbox", 100, compVarName }
		tOpts[#tOpts+1] = entry
	end
	
	local switchOptions = 
	{
        onPress = onSwitchPress
    }
	local sizingSpots = math.min( 7, #tOpts )
	local numSpots = 1 + ( sizingSpots + 1 ) * 2
	switchOptions.height = ( display.contentHeight - canvasTop ) / numSpots

	if #tOpts > 7 then
		local scrollTop = canvasTop + ( switchOptions.height * 3 * 2 ) - ( switchOptions.height / 2 )
		local scrollHeight = appCanvasHeight - scrollTop - switchOptions.height
		scrollView = widget.newScrollView
		{
			width = _W,
			height = scrollHeight,
			scrollWidth = _W,
			scrollHeight = #tOpts * switchOptions.height,
			horizontalScrollDisabled = true
		}
		scrollView.x = display.contentCenterX
		scrollView.y = scrollTop
		scrollView.anchorY = 0
		scrollViewBackground = display.newRect( 0, 0, _W, #tOpts * switchOptions.height )
		scrollViewBackground:setFillColor( 		{
			type = 'gradient',
			color1 = { 1, 1, 1, 1 }, 
			color2 = { .8, .8, .8, 1 },
			direction = "down"
		} )
		scrollViewBackground.anchorX = 0
		scrollViewBackground.anchorY = 0
		scrollView:insert( scrollViewBackground )
		sceneGroup:insert( scrollView )
	end
	
	local tempNum
   	for i=1,#tOpts do
		-- Button Specific Options
		switchOptions.id = tOpts[i][1]
		switchOptions.style = tOpts[i][2]		
		if switchOptions.style == "radio" then
			switchOptions.initialSwitchState = composer.getVariable( tOpts[i][4] )
		else
			switchOptions.initialSwitchState = composer.getVariable( compVarName ):find( switchOptions.id ) ~= nil
		end
		
		local textX
		local textY
		local switchGroup
		local textGroup
		if i < 3 then
			switchGroup = radioGroup
			switchOptions.left = tOpts[i][3]
			switchOptions.top = canvasTop + ( switchOptions.height * i * 2 ) - ( switchOptions.height / 2 )		
			
			textGroup = radioGroup
			textX = switchOptions.left + 35
			textY = canvasTop + ( switchOptions.height * i * 2 )
		else
			if #tOpts < 8 then
				switchGroup = radioGroup
				switchOptions.left = tOpts[i][3]
				switchOptions.top = canvasTop + ( switchOptions.height * i * 2 ) - ( switchOptions.height / 2 )		
				
				textGroup = sceneGroup
				textX = switchOptions.left + 35
				textY = canvasTop + ( switchOptions.height * i * 2 )
			else
				switchGroup = scrollView
				switchOptions.left = tOpts[i][3]
				switchOptions.top = ( switchOptions.height * ( i -2 ) ) - ( switchOptions.height / 2 )		
				
				textGroup = scrollView
				textX = tOpts[i][3] + 35
				textY = ( switchOptions.height * ( i-2 ) )
			end
		end
		-- Create and Add
		switchButtons[i] = {}
		switchButtons[i].button = widget.newSwitch( switchOptions )
		switchGroup:insert( switchButtons[i].button )
		switchButtons[i].text, tempNum = AddText( textGroup, tOpts[i][1], 14, 0, 0, 0, 1, textX, textY, 0 )
		switchButtons[i].text.anchorX = 0
		--textGroup:insert( switchButtons[i].text )
	end

	local buttonOptions = 
	{
		label = "Done",
		emboss = false,
		shape="roundedRect",
		anchorX = 0.5,
		width = _W*.8,
		height = switchOptions.height,
		cornerRadius = 10,
		labelColor = { default={ 0, 0, 0, 1 }, over={ .1, 0.1, 0.1, 1 } },
		fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
		strokeColor = { default=theme[4].Color, over={ 0, 0, 0, 1 } },
		strokeWidth = 5,	
		onRelease = QOptionsDone
	}
	doneButton = widget.newButton( buttonOptions )
	doneButton.x = display.contentWidth * 0.5
	doneButton.y = canvasTop + ( buttonOptions.height * (sizingSpots+1) * 2 ) - ( buttonOptions.height / 2 )
	sceneGroup:insert( doneButton )
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
		local checkBoxAlpha = 1
		if composer.getVariable( tOpts[1][4] ) then
			checkBoxAlpha = 0
		end
	   	for i=1,#tOpts do
			if tOpts[i][2] == "radio" then
				switchButtons[i].button.alpha = 1
				switchButtons[i].text.alpha = 1
				switchButtons[i].button.isOn = composer.getVariable( tOpts[i][4] )
			else
				switchButtons[i].button.alpha = checkBoxAlpha
				switchButtons[i].text.alpha = checkBoxAlpha + 0.5
				switchButtons[i].button.isOn = composer.getVariable( compVarName ):find( switchButtons[i].button.id ) ~= nil
			end
		end
    elseif ( phase == "did" ) then
    end
end

function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
    local typeList = ""
    if ( phase == "will" ) then
	   	for i=1,#tOpts do
			if tOpts[i][2] == "radio" then
				composer.setVariable( tOpts[i][4], switchButtons[i].button.isOn )
			else
				if switchButtons[i].button.isOn then
					typeList = typeList .. '|' .. switchButtons[i].button.id
				end
			end
		end
		composer.setVariable( compVarName, typeList )
    elseif ( phase == "did" ) then
    end
end

function scene:destroy( event )
    local sceneGroup = self.view
	
	optHeader:removeSelf()
	optText:removeSelf()
	for i=1,#switchButtons do
		switchButtons[i].button:removeSelf()
	end
	doneButton:removeSelf()
	if scrollView then
		scrollViewBackground:removeSelf()
		scrollView:removeSelf()
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene