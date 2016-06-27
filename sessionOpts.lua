local scene = composer.newScene()

local canvasTop

local optHeader
local optText
local sOptButtons = {}

local numQuestions = 
{
	--{ id, "Button Label" },

	{ 10, "Ten (10)" },
	{ 20, "Twenty (20)" },
	{ 50, "Fifty (50)" },
	{ 75, "Seventy Five (75)" },
	{ 100, "One Hundred (100)" },
}

local function NumQuestions( event )
	composer.setVariable( "numQs", event.target.id )
	composer.hideOverlay( "sessionOpts", 200 )
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
	optHeader, nextTop = AddText( sceneGroup, "Session Options", 20, 0, 0, 0, 1, _W/2.0, event.params.originY+15, 10 );
	optText, nextTop = AddText( sceneGroup, "Number of Questions", 16, 0, 0, 0, 1, _W/2.0, nextTop, 0 );
	
	local buttonOptions = 
	{
		emboss = false,
		shape="roundedRect",
		anchorX = 0.5,
		width = _W*.8,
		cornerRadius = 10,
		labelColor = { default={ 0, 0, 0, 1 }, over={ .1, 0.1, 0.1, 1 } },
		fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
		strokeColor = { default=theme[4].Color, over={ 0, 0, 0, 1 } },
		strokeWidth = 5,	
		onRelease = NumQuestions
	}
	local numSpots = 1 + #numQuestions * 2
	buttonOptions.height = ( display.contentHeight - nextTop ) / numSpots

   	for i=1,#numQuestions do
	-- Button Specific Options
		buttonOptions.id = numQuestions[i][1]
		buttonOptions.label = numQuestions[i][2]
		-- Create and Add
		sOptButtons[i] = widget.newButton( buttonOptions )
		sOptButtons[i].x = display.contentWidth * 0.5
		sOptButtons[i].y = nextTop + ( buttonOptions.height * i * 2 ) - ( buttonOptions.height / 2 )
		sceneGroup:insert( sOptButtons[i] )
	end
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
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
   	for i=1,#sOptButtons do
		sOptButtons[i]:removeSelf()
	end	
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene