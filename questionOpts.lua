local scene = composer.newScene()

local switchButtons = {}
local optHeader
local optText
local doneButton

local canvasTop

local qOpts = 
{
	--{ id, "switch type", initState, left, "composerVarName" },

	{ "ANY", "radio", 50, "askAny" },
	{ "Select Types", "radio", 50, "askSel"  },
	{ "New Questions", "checkbox", 100, "askNew" },
	{ "Guessed Questions", "checkbox", 100, "askGuessed" },
	{ "Missed Questions", "checkbox", 100, "askMissed" },
}

local function QOptionsDone( event )
	composer.hideOverlay( "questionOpts", 200 )
end

local function onSwitchPress( event )
	for i=1, #switchButtons do
		if event.target == switchButtons[i].button then		
			-- set new values
			composer.setVariable( qOpts[i][4], switchButtons[i].button.isOn )
			
			-- Turn off/on check boxes based on radio buttons
			if qOpts[i][2] == "radio" then
				local alpha = 1
				if event.target.id == "ANY" then
					alpha = 0
				end
				for j=1, #switchButtons do
					if qOpts[j][2] ~= "radio" then
						switchButtons[j].button.alpha = alpha
						switchButtons[j].text.alpha = alpha + 0.5
					else
						composer.setVariable( qOpts[j][4], switchButtons[j].button.isOn )
					end
				end
			end
			
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
	optHeader, canvasTop = AddText( sceneGroup, "Question Options", 20, 0, 0, 0, 1, _W/2.0, event.params.originY+15, 10 )
	optText, canvasTop = AddText( sceneGroup, "Ask Which Questions", 16, 0, 0, 0, 1, _W/2.0, canvasTop, 0 )

	local radioGroup = display.newGroup()	
	sceneGroup:insert( radioGroup )
	
	local switchOptions = 
	{
        onPress = onSwitchPress
    }
	local numSpots = 1 + ( #qOpts + 1 ) * 2
	switchOptions.height = ( display.contentHeight - canvasTop ) / numSpots
	local tempNum

   	for i=1,#qOpts do
	-- Button Specific Options
		switchOptions.id = qOpts[i][1]
		switchOptions.style = qOpts[i][2]
		switchOptions.initialSwitchState = composer.getVariable( qOpts[i][4] )
		switchOptions.left = qOpts[i][3]
		switchOptions.top = canvasTop + ( switchOptions.height * i * 2 ) - ( switchOptions.height / 2 )		
		-- Create and Add
		switchButtons[i] = {}
		switchButtons[i].button = widget.newSwitch( switchOptions )
		radioGroup:insert( switchButtons[i].button )
		
		local textY = canvasTop + ( switchOptions.height * i * 2 )
		switchButtons[i].text, tempNum = AddText( sceneGroup, qOpts[i][1], 14, 0, 0, 0, 1, qOpts[i][3]+35, textY, 0 )
		switchButtons[i].text.anchorX = 0
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
	doneButton.y = canvasTop + ( buttonOptions.height * (#qOpts+1) * 2 ) - ( buttonOptions.height / 2 )
	sceneGroup:insert( doneButton )
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
		local checkBoxAlpha = 1
		if composer.getVariable( qOpts[1][4] ) then
			checkBoxAlpha = 0
		end
	   	for i=1,#qOpts do
			if qOpts[i][2] == "radio" then
				switchButtons[i].button.alpha = 1
				switchButtons[i].text.alpha = 1
			else
				switchButtons[i].button.alpha = checkBoxAlpha
				switchButtons[i].text.alpha = checkBoxAlpha + 0.5
			end
			switchButtons[i].button.isOn = composer.getVariable( qOpts[i][4] )
		end
    elseif ( phase == "did" ) then
    end
end

function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
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
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene