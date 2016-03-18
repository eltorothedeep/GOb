local graphUI = {}
graphUI.graphScreen = display.newGroup()
local graphType = 1
local graphDetails
	
local fullRect = display.newRect( _W/2,_H/2,_W,_H )
fullRect:setFillColor(190/255, 190/255, 1, 0.5)
local yAxis = display.newLine( graphUI.graphScreen, 0, 30, _W, 30 )
local xAxis = display.newLine( graphUI.graphScreen, 30, 0, 30, _H )
xAxis.strokeWidth = 2
yAxis.strokeWidth = 2
local tickDist = ( _H-60 ) / 11
for i=1,10 do
	display.newLine( graphUI.graphScreen, 25, 30+(i*tickDist), 35, 30+(i*tickDist) )
end
local graphName = display.newText( graphUI.graphScreen, "Graph Name", 0, _H/2, native.systemFontBold, 18 )
graphName:setFillColor(190/255, 190/255, 1, 1)
graphName.x = graphName.height/2
graphName.anchorX=0.5
graphName.anchorY=0.5
graphName:rotate( 90 )
transition.to( graphUI.graphScreen, { alpha=0, time = 0, transition = easing.outQuad } )

local function DrawGraph()
	OpenDatabases( false )
	graphDetails = display.newGroup()
	graphUI.graphScreen:insert( graphDetails )
	local maxSessions
	for x in GetUserDB():urows "SELECT COUNT(*) FROM Sessions;" do 
		maxSessions = x
	end
	local graphData = {}
	local minVal = 10000000
	local maxVal = -1
	while #graphData<10 and maxSessions-#graphData>0 do
		local query = [[SELECT COUNT(*) FROM Attempts WHERE sessionid=]] .. maxSessions-#graphData .. [[ ;]]
		local numAttempts
		for x in GetUserDB():urows(query) do 
			numAttempts = x
		end
		if graphType == 1 then
			graphData[#graphData+1] = numAttempts
			if numAttempts<minVal then minVal=numAttempts end 
			if numAttempts>maxVal then maxVal=numAttempts end
		else
			query = "SELECT COUNT(*) FROM Attempts WHERE sessionid=" .. maxSessions-#graphData .. " AND result='" .. theme[graphType].id .. "';"
			for x in GetUserDB():urows(query) do 
				local data = 0
				if numAttempts > 0 then
					data =  WholePercent( x / numAttempts ) 
				end
				graphData[#graphData+1] = data
				print( data )
				if data<minVal then minVal=data end 
				if data>maxVal then maxVal=data end
			end
		end
	end
	local vertDist 
	if graphType == 1 then
		vertDist = ( _W-60 ) / maxVal
	else
		vertDist = ( _W-60 ) / 100
	end
	if #graphData > 1 then
		local count = #graphData
		while count > 1 do
			local i = 1 + #graphData - count
			local line = display.newLine( graphDetails, 30+graphData[count]*vertDist, (30+(tickDist*(i))), 30+graphData[count-1]*vertDist, (30+(tickDist*(i+1))))
			line.strokeWidth = 2
			line:setStrokeColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
			local dot = display.newCircle( graphDetails, 30+graphData[count]*vertDist, (30+(tickDist*(i))), 4 )
			dot:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
			local label = display.newText( graphDetails, tostring(graphData[count]), 45+graphData[count]*vertDist, (30+(tickDist*(i))), native.systemFontBold, 16 )
			label:rotate(90)
			label:setFillColor(190/255, 190/255, 1, 1)
			count = count - 1
		end
		local dot = display.newCircle( graphDetails, 30+graphData[1]*vertDist, (30+(tickDist*(#graphData))), 4 )
		dot:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
		local label = display.newText( graphDetails, tostring(graphData[1]), 45+graphData[1]*vertDist, (30+(tickDist*(#graphData))), native.systemFontBold, 16 )
		label:rotate(90)
		label:setFillColor(190/255, 190/255, 1, 1)
	elseif #graphData == 1 then
		display.newCircle( graphDetails, 30+graphData[1]*vertDist, (30+tickDist), 4 )
	end
	CloseUserDB()
end

local function DrawNextGraph( target )
	if graphDetails then
		graphDetails:removeSelf()
	end
	if graphType == 1 then
		graphName.text = theme[graphType].id .. ' in Last 10 Sessions'
	else
		graphName.text = 'Percent ' .. theme[graphType].id .. ' in Last 10 Sessions'
	end
	DrawGraph()
end

local function HandleSwipe( event )
	--print( event.phase )
	if event.phase == "moved" then
		local dY = event.y - event.yStart
		transition.to( graphDetails, { time=50, y=dY } )
    elseif ( event.phase == "ended" ) then
        local dY = event.y - event.yStart
        --print( event.x, event.xStart, dX )
        if ( dY > _H*.15 ) then
            --swipe right
            transition.to( graphDetails, { time=500, y=_H*2, onComplete=DrawNextGraph } )
			graphType = graphType - 1
			if graphType == 0 then graphType = 4 end
        elseif ( dY  < _H*-0.15 ) then
            transition.to( graphDetails, { time=500, y=_H*-1, onComplete=DrawNextGraph } )
			graphType = graphType + 1
			if graphType == 5 then graphType = 1 end
        else
			transition.to( graphDetails, { time=100, y=0, onComplete=DrawNextGraph } )
		end
    end
    return true
end
			
graphUI.TransitionOut = function()
	if graphDetails then
		graphDetails:removeSelf()
	end
	transition.to( graphUI.graphScreen, { alpha=0, time = timeToTransition, transition = easing.outQuad } )
end

graphUI.TransitionIn= function()
	transition.to( graphUI.graphScreen, { alpha=1, time = timeToTransition, transition = easing.outExpo } )	
	graphType = 1
	DrawNextGraph()
end

fullRect:addEventListener( "touch", HandleSwipe )

return graphUI