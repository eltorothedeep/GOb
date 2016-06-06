local welcomeUI = {}
welcomeUI.screen = display.newGroup()

-- Add onscreen text
local label1 = display.newText( welcomeUI.screen, "Geo Quiz", _W/2.0, appOriginY, native.systemFontBold, 24 )
label1:setFillColor( 190/255, 190/255, 1, 1 )

nextTop = appOriginY + label1.height-- + space
local cumStats = display.newText( welcomeUI.screen, "Cumulative Stats:", space, nextTop, native.systemFontBold, 16 )
cumStats.anchorX = 0
cumStats.anchorY = 0
nextTop = nextTop + cumStats.height
display.newLine( welcomeUI.screen, space, nextTop, cumStats.width*1.1, nextTop )

local cumStatInfoLabels = {}
local cumStatInfoValues = {}
nextTop = nextTop + space
for i=1,#theme do
	cumStatInfoLabels[i] = display.newText( welcomeUI.screen, theme[i].id..": ", space, nextTop, native.systemFontBold, 16 )
	cumStatInfoLabels[i].anchorX = 0
	cumStatInfoLabels[i].anchorY = 0
	cumStatInfoLabels[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )

	cumStatInfoValues[i] = display.newText( welcomeUI.screen, "", _W/2, nextTop, native.systemFontBold, 16 )
	cumStatInfoValues[i].anchorX = 0
	cumStatInfoValues[i].anchorY = 0
	cumStatInfoValues[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )
	
	nextTop = nextTop + cumStatInfoValues[i].height + space
end

nextTop = nextTop + space
local lastStats = display.newText( welcomeUI.screen, "Last Session Stats:", space, nextTop, native.systemFontBold, 16 )
lastStats.anchorX = 0
lastStats.anchorY = 0
nextTop = nextTop + lastStats.height
display.newLine( welcomeUI.screen, space, nextTop, lastStats.width*1.1, nextTop )

nextTop = nextTop + space
local lTimeL = display.newText( welcomeUI.screen, "Total Time: ", space, nextTop, native.systemFontBold, 16 )
local lTimeV = display.newText( welcomeUI.screen, "", _W/2, nextTop, native.systemFontBold, 16 )
lTimeL.anchorX = 0
lTimeL.anchorY = 0
lTimeV.anchorX = 0
lTimeV.anchorY = 0
lTimeL:setFillColor( theme[1].Color[1], theme[1].Color[2], theme[1].Color[3], theme[1].Color[4])
lTimeV:setFillColor( theme[1].Color[1], theme[1].Color[2], theme[1].Color[3], theme[1].Color[4])

nextTop = nextTop + lTimeV.height + space
local lSpeedL = display.newText( welcomeUI.screen, "Time/Question: ", space, nextTop, native.systemFontBold, 16 )
local lSpeedV = display.newText( welcomeUI.screen, "", _W/2, nextTop, native.systemFontBold, 16 )
lSpeedL.anchorX = 0
lSpeedL.anchorY = 0
lSpeedV.anchorX = 0
lSpeedV.anchorY = 0
lSpeedL:setFillColor( theme[1].Color[1], theme[1].Color[2], theme[1].Color[3], theme[1].Color[4])
lSpeedV:setFillColor( theme[1].Color[1], theme[1].Color[2], theme[1].Color[3], theme[1].Color[4])

nextTop = nextTop + lSpeedL.height + space
local lastStatInfoLabels = {}
local lastStatInfoValues = {}
for i=1,#theme do
	lastStatInfoLabels[i] = display.newText( welcomeUI.screen, theme[i].id..": ", space, nextTop, native.systemFontBold, 16 )
	lastStatInfoLabels[i].anchorX = 0
	lastStatInfoLabels[i].anchorY = 0
	lastStatInfoLabels[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )

	lastStatInfoValues[i] = display.newText( welcomeUI.screen, "", _W/2, nextTop, native.systemFontBold, 16 )
	lastStatInfoValues[i].anchorX = 0
	lastStatInfoValues[i].anchorY = 0
	lastStatInfoValues[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )
	
	nextTop = nextTop + lastStatInfoValues[i].height + space
end

local function GoToQuiz( event )
	StartSession()
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
	onRelease = GoToQuiz
}
startButton.anchorX = 0.5
startButton.anchorY = 0.5
startButton.x = display.contentWidth * 0.5
startButton.y = _H - ( buttonHeight )
welcomeUI.screen:insert( startButton )


welcomeUI.TransitionIn = function( timeToTransition, updateInfo )
	if updateInfo then
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
		
		if sessionID == 0 then
			for x in udb:urows "SELECT COUNT(*) FROM Sessions;" do 
				sessionID = x
			end			
		end
		if sessionID > 0 then
			local sessionLen, h,m,s
			for x in udb:rows([[SELECT * FROM Sessions WHERE id=]] .. sessionID .. [[ ;]]) do 
				sessionLen = x[6]
				if sessionLen == nil then sessionLen = 30 end
				local length = sessionLen
				h = length/3600 - (length/3600)%1
				length = length - h*3600
				m = length/60 - (length/60)%1
				s = length - m
			end
			lTimeV.text = h .. ':' .. m .. ':' .. s
			--print( 'Last Session Time: ' .. h .. '-Hours, ' .. m .. '-Minutes, ' .. s .. '-Seconds' )
			for x in udb:urows([[SELECT COUNT(*) FROM Attempts WHERE sessionid=]] .. sessionID .. [[ ;]]) do 
				numAttempts = x
			end
			lastStatInfoValues[1].text =  tostring( numAttempts )
			if numAttempts > 0 then
				--print( "Last Session Attempts: " .. numAttempts)
				lSpeedV.text = tostring( sessionLen/numAttempts )
				--print( "Second per Attempts: " .. sessionLen/numAttempts )
				
				for i=2,#theme do
					local value
					for x in udb:urows( "SELECT COUNT(*) FROM Attempts WHERE sessionid=" .. sessionID .. " AND result='" ..theme[i].id.."';" ) do 
						value = x
					end
					lastStatInfoValues[i].text =  tostring( value ) .. ' ( ' .. WholePercent( value/numAttempts ) .. '% )'
				end
			end
		end
	end
	
	transition.to( welcomeUI.screen, { alpha=1, time = timeToTransition, transition = easing.outExpo } )	
end

welcomeUI.TransitionOut = function( timeToTransition )
	transition.to( welcomeUI.screen, { alpha=0, time = timeToTransition, transition = easing.outQuad } )
end

return welcomeUI