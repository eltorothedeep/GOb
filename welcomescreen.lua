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

	cumStats = display.newText( sceneGroup, "Cumulative Stats:", space, nextTop, native.systemFontBold, 16 )
	cumStats.anchorX = 0
	cumStats.anchorY = 0
	nextTop = nextTop + cumStats.height
	display.newLine( sceneGroup, space, nextTop, cumStats.width*1.1, nextTop )

	nextTop = nextTop + space
	for i=1,#theme do
		cumStatInfoLabels[i] = display.newText( sceneGroup, theme[i].id..": ", space, nextTop, native.systemFontBold, 16 )
		cumStatInfoLabels[i].anchorX = 0
		cumStatInfoLabels[i].anchorY = 0
		cumStatInfoLabels[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )

		cumStatInfoValues[i] = display.newText( sceneGroup, "", _W/2, nextTop, native.systemFontBold, 16 )
		cumStatInfoValues[i].anchorX = 0
		cumStatInfoValues[i].anchorY = 0
		cumStatInfoValues[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )
		
		nextTop = nextTop + cumStatInfoValues[i].height + space
	end

	nextTop = nextTop + space
	lastStats = display.newText( sceneGroup, "Last Session Stats:", space, nextTop, native.systemFontBold, 16 )
	lastStats.anchorX = 0
	lastStats.anchorY = 0
	nextTop = nextTop + lastStats.height
	display.newLine( sceneGroup, space, nextTop, lastStats.width*1.1, nextTop )

	nextTop = nextTop + space
	lTimeL = display.newText( sceneGroup, "Total Time: ", space, nextTop, native.systemFontBold, 16 )
	lTimeV = display.newText( sceneGroup, "", _W/2, nextTop, native.systemFontBold, 16 )
	lTimeL.anchorX = 0
	lTimeL.anchorY = 0
	lTimeV.anchorX = 0
	lTimeV.anchorY = 0
	lTimeL:setFillColor( theme[1].Color[1], theme[1].Color[2], theme[1].Color[3], theme[1].Color[4])
	lTimeV:setFillColor( theme[1].Color[1], theme[1].Color[2], theme[1].Color[3], theme[1].Color[4])

	nextTop = nextTop + lTimeV.height + space
	lSpeedL = display.newText( sceneGroup, "Time/Question: ", space, nextTop, native.systemFontBold, 16 )
	lSpeedV = display.newText( sceneGroup, "", _W/2, nextTop, native.systemFontBold, 16 )
	lSpeedL.anchorX = 0
	lSpeedL.anchorY = 0
	lSpeedV.anchorX = 0
	lSpeedV.anchorY = 0
	lSpeedL:setFillColor( theme[1].Color[1], theme[1].Color[2], theme[1].Color[3], theme[1].Color[4])
	lSpeedV:setFillColor( theme[1].Color[1], theme[1].Color[2], theme[1].Color[3], theme[1].Color[4])

	nextTop = nextTop + lSpeedL.height + space
	for i=1,#theme do
		lastStatInfoLabels[i] = display.newText( sceneGroup, theme[i].id..": ", space, nextTop, native.systemFontBold, 16 )
		lastStatInfoLabels[i].anchorX = 0
		lastStatInfoLabels[i].anchorY = 0
		lastStatInfoLabels[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )

		lastStatInfoValues[i] = display.newText( sceneGroup, "", _W/2, nextTop, native.systemFontBold, 16 )
		lastStatInfoValues[i].anchorX = 0
		lastStatInfoValues[i].anchorY = 0
		lastStatInfoValues[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )
		
		nextTop = nextTop + lastStatInfoValues[i].height + space
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
			for x in udb:urows "SELECT COUNT(*) FROM Attempts;" do 
				numAttempts = x
			end
			cumStatInfoValues[1].text = tostring( numAttempts)
			--print( "Total Attempts: " .. numAttempts)
			if numAttempts > 0 then
				for i=2,#theme do 
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
				if numAttempts > 0 then
					--print( "Last Session Attempts: " .. numAttempts)
					lSpeedV.text = tostring( sessionLen/numAttempts )
					--print( "Second per Attempts: " .. sessionLen/numAttempts )
					
					for i=2,#theme do
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
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene