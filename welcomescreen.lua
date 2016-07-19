local scene = composer.newScene()

-- Display elements in the screen
local header
local cumStats = nil
local cumStatInfoLabels = {}
local cumStatInfoValues = {}
local lastStats = nil
local lTimeL = nil
local lTimeV = nil
local lSpeedL = nil
local lSpeedV = nil
local lastStatInfoLabels = {}
local lastStatInfoValues = {}
local startButton = nil
local scrollView = nil
local scrollViewBackground = nil

-- Local Variables
local displayFontSize = 16
if system.getInfo( "platformName" ) == "Win" then
	displayFontSize = 12
end

local function GoToQuizOptions( event )
	local options = 
	{
		effect = "fade",
		time = 400,
	}	
	composer.gotoScene( "quizoptions", options )
end

-- Scene Interface

function scene:create( event )
    local sceneGroup = self.view
	
	local nextTop 
	header, nextTop = AddText( sceneGroup, "Geo Quiz", 24, 190/255, 190/255, 1, 1, _W/2.0, appOriginY, 0 );
	
	local switchOptions = 
	{
        onPress = onSwitchPress
    }
	local numSpots = 16
	switchOptions.height = ( display.contentHeight - nextTop ) / numSpots

	local scrollTop = nextTop --+ ( switchOptions.height * 3 * 2 ) - ( switchOptions.height / 2 )
	local scrollHeight = appCanvasHeight - scrollTop - switchOptions.height
	scrollView = widget.newScrollView
	{
		width = _W,
		height = scrollHeight,
		scrollWidth = _W,
		scrollHeight = numSpots * switchOptions.height,
		horizontalScrollDisabled = true
	}
	scrollView.x = display.contentCenterX
	scrollView.y = scrollTop
	scrollView.anchorY = 0
	scrollViewBackground = display.newRect( 0, 0, _W, numSpots * switchOptions.height )
	scrollViewBackground:setFillColor( 		{
		type = 'gradient',
		color1 = { 0, 0, 0, 1 }, 
		color2 = { .1, .1, .1, 1 },
		direction = "down"
	} )
	scrollViewBackground.anchorX = 0
	scrollViewBackground.anchorY = 0
	scrollView:insert( scrollViewBackground )
	sceneGroup:insert( scrollView )
	
	cumStats, nextTop = AddText( scrollView, "Cumulative Stats:", displayFontSize,1,1,1,1, space, 10, 0 )
	cumStats.anchorX = 0
	cumStats.anchorY = 0
	
	local line1 = display.newLine( space, nextTop, cumStats.width*1.1, nextTop )
	scrollView:insert( line1 )
	nextTop = nextTop + space

	for i=1,#theme do
		local curTop = nextTop
		cumStatInfoLabels[i], nextTop = AddText( scrollView, theme[i].id..": ", displayFontSize, theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4], space*3, nextTop, 5 )
		cumStatInfoLabels[i].anchorX = 0
		cumStatInfoLabels[i].anchorY = 0

		cumStatInfoValues[i], nextTop = AddText( scrollView, "", displayFontSize, theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4], _W/2, curTop, 5 )
		cumStatInfoValues[i].anchorX = 0
		cumStatInfoValues[i].anchorY = 0
	end

	nextTop = nextTop + space*2
	lastStats, nextTop = AddText( scrollView, "Last Session Stats:", displayFontSize,1,1,1,1, space, nextTop, 0 )
	lastStats.anchorX = 0
	lastStats.anchorY = 0
	local line2 = display.newLine( space, nextTop, lastStats.width*1.1, nextTop )
	scrollView:insert( line2 )
	nextTop = nextTop + space

	local curTop = nextTop
	lTimeL, nextTop = AddText( scrollView, "Total Time: ", displayFontSize,1,1,1,1, space*3, nextTop, 5 )
	lTimeL.anchorX = 0
	lTimeL.anchorY = 0
	lTimeV, nextTop = AddText( scrollView, "", displayFontSize,1,1,1,1, _W/2, curTop, 5 )
	lTimeV.anchorX = 0
	lTimeV.anchorY = 0

	curTop = nextTop
	lSpeedL, nextTop = AddText( scrollView, "Time/Question: ", displayFontSize,1,1,1,1, space*3, nextTop, 5 )
	lSpeedL.anchorX = 0
	lSpeedL.anchorY = 0
	lSpeedV, nextTop = AddText( scrollView, "", displayFontSize,1,1,1,1, _W/2, curTop, 5 )
	lSpeedV.anchorX = 0
	lSpeedV.anchorY = 0

	for i=1,#theme do
		local curTop = nextTop
		lastStatInfoLabels[i], nextTop = AddText( scrollView, theme[i].id..": ", displayFontSize, theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4], space*3, nextTop, 5 )
		lastStatInfoLabels[i].anchorX = 0
		lastStatInfoLabels[i].anchorY = 0

		lastStatInfoValues[i], nextTop = AddText( scrollView, "", displayFontSize, theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4], _W/2, curTop, 5 )
		lastStatInfoValues[i].anchorX = 0
		lastStatInfoValues[i].anchorY = 0
	end
	
	startButton = widget.newButton
	{
		id = "START",
		label = "Start Session", 
		emboss = false,
		shape="roundedRect",
		width = _W*.8,
		height = buttonHeight*.75,
		cornerRadius = 10,
		labelColor = { default={ 0.3, 0.85, 0.3, 1 }, over={ .1, 0.1, 0.1, 1 } },
		fillColor = { default={ 0,0,0, 1 }, over={ 1, 1, 1, 0.6 } },
		strokeColor = { default={ 190/255, 190/255, 1, 1 }, over={ 0, 0, 0, 1 } },
		strokeWidth = 5,	
		onRelease = GoToQuizOptions
	}
	startButton.anchorX = 0.5
	startButton.anchorY = 0.5
	startButton.x = display.contentWidth * 0.5
	startButton.y = _H - ( buttonHeight )
	sceneGroup:insert( startButton )
	
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
		if event.params and event.params.updateInfo and event.params.updateInfo == true then
			OpenDatabases( false )
			for x in udb:urows "SELECT COUNT(*) FROM Attempts;" do 
				numAttempts = x
			end
			cumStatInfoValues[1].text = tostring( numAttempts)

			local totalScore = 0
			local totalMaxScore = 0
			for x in udb:rows "SELECT * FROM Sessions;" do 
				if x[7] ~= nil then
					local numSessionAttempts = 0
					for numA in udb:urows( "SELECT COUNT(*) FROM Attempts WHERE sessionid='"..x[1].."';" ) do  
						numSessionAttempts = numA
					end
					if numSessionAttempts > 0 then
						totalScore = totalScore + x[7]
						totalMaxScore = totalMaxScore + ( numSessionAttempts * 1000 )
						print( x[7], numSessionAttempts )
					end
				end
			end
			
			if totalMaxScore > 0 then
				cumStatInfoValues[2].text = tostring( WholePercent( totalScore / totalMaxScore ) ) .. '%'
			else
				cumStatInfoValues[2].text = '0%'
			end
			--print( "Total Attempts: " .. numAttempts)
			if numAttempts > 0 then
				for i=3,#theme do 
					local value					
					for x in udb:urows( "SELECT COUNT(*) FROM Attempts WHERE result='" ..theme[i].id.."';") do 
						value = x
					end
					cumStatInfoValues[i].text = tostring( value ) .. ' ( ' .. WholePercent( value/numAttempts ) .. '% )'
				end
			end
			
			local lastSessionID
			for x in udb:urows "SELECT COUNT(*) FROM Sessions;" do 
				lastSessionID = x
			end			
			if lastSessionID > 0 then
				local sessionLen, h,m,s
				for x in udb:rows([[SELECT * FROM Sessions WHERE id=]] .. lastSessionID .. [[ ;]]) do 
					sessionLen = x[6]
					if sessionLen == nil then sessionLen = 30 end
					local length = sessionLen
					h = length/3600 - (length/3600)%1
					length = length - h*3600
					m = length/60 - (length/60)%1
					s = length - m*60
				end
				lTimeV.text = h .. ':' .. m .. ':' .. s
				--print( 'Last Session Time: ' .. h .. '-Hours, ' .. m .. '-Minutes, ' .. s .. '-Seconds' )
				for x in udb:urows([[SELECT COUNT(*) FROM Attempts WHERE sessionid=]] .. lastSessionID .. [[ ;]]) do 
					numAttempts = x
				end
				lastStatInfoValues[1].text =  tostring( numAttempts )
				
				local scorePercent = 0
				if numAttempts > 0 then
					for x in udb:urows([[SELECT score FROM Sessions WHERE id=]] .. lastSessionID .. [[ ;]]) do 
						print( x, numAttempts )
						scorePercent = WholePercent( x / ( numAttempts*1000 ) )
					end
				else
					scorePercent = 0
				end
				lastStatInfoValues[2].text =  tostring( scorePercent ) .. '%'
				
				if numAttempts > 0 then
					--print( "Last Session Attempts: " .. numAttempts)
					lSpeedV.text = tostring( sessionLen/numAttempts )
					--print( "Second per Attempts: " .. sessionLen/numAttempts )
					
					for i=3,#theme do
						local value
						for x in udb:urows( "SELECT COUNT(*) FROM Attempts WHERE sessionid=" .. lastSessionID .. " AND result='" ..theme[i].id.."';" ) do 
							value = x
						end
						lastStatInfoValues[i].text =  tostring( value ) .. ' ( ' .. WholePercent( value/numAttempts ) .. '% )'
					end
				end
			end
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
	header:removeSelf()
	cumStats:removeSelf()
	lastStats:removeSelf()
	lTimeL:removeSelf()
	lTimeV:removeSelf()
	lSpeedL:removeSelf()
	lSpeedV:removeSelf()
	startButton:removeSelf()
	
	for i=1,#theme do
		cumStatInfoLabels[i]:removeSelf()
		cumStatInfoValues[i]:removeSelf()
		lastStatInfoLabels[i]:removeSelf()
		lastStatInfoValues[i]:removeSelf()
	end
	
	scrollViewBackground:removeSelf()
	scrollView:removeSelf()

end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene