local composer = require( "composer" )
local scene = composer.newScene()

-- Display Controls
local graphDetails = nil
local fullRect
local yAxis
local xAxis 
local xTicks = {}
local graphName

-- Local Vars
local graphType = 1
local tickDist = ( _H-60 ) / 11

local function DrawGraph()
	OpenDatabases( false )
	graphDetails = display.newGroup()
	scene.view:insert( graphDetails )
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
		elseif graphType == 2 then
			query = "SELECT * FROM Sessions WHERE id=" .. maxSessions-#graphData .. ";"
			for x in GetUserDB():rows(query) do 
				-- For entries before the Score was added
				if x[7] == nil then x[7] = 0 end
				
				local scorePercent = 0
				if numAttempts > 0 then
					scorePercent = WholePercent( x[7] / ( numAttempts * 1000 ) ) 
				end
				graphData[#graphData+1] =  scorePercent
			end
		else
			query = "SELECT COUNT(*) FROM Attempts WHERE sessionid=" .. maxSessions-#graphData .. " AND result='" .. theme[graphType].id .. "';"
			for x in GetUserDB():urows(query) do 
				local data = 0
				if numAttempts > 0 then
					data =  WholePercent( x / numAttempts ) 
				end
				graphData[#graphData+1] = data
				--print( data )
			end
		end
		if graphData[#graphData]<minVal then minVal=graphData[#graphData] end 
		if graphData[#graphData]>maxVal then maxVal=graphData[#graphData] end		
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
			if graphType == 0 then graphType = #theme end
        elseif ( dY  < _H*-0.15 ) then
            transition.to( graphDetails, { time=500, y=_H*-1, onComplete=DrawNextGraph } )
			graphType = graphType + 1
			if graphType == #theme+1 then graphType = 1 end
        else
			transition.to( graphDetails, { time=100, y=0, onComplete=DrawNextGraph } )
		end
    end
    return true
end


function scene:create( event )
    local sceneGroup = self.view

	fullRect = display.newRect( _W/2,_H/2,_W,_H )
	fullRect:setFillColor(190/255, 190/255, 1, 0.5)
	fullRect:addEventListener( "touch", HandleSwipe )
	sceneGroup:insert( fullRect )

	yAxis = display.newLine( sceneGroup, 0, 30, _W, 30 )
	xAxis = display.newLine( sceneGroup, 30, 0, 30, _H )
	xAxis.strokeWidth = 2
	yAxis.strokeWidth = 2
	for i=1,10 do
		xTicks[i] = display.newLine( sceneGroup, 25, 30+(i*tickDist), 35, 30+(i*tickDist) )
	end
	graphName = display.newText( sceneGroup, "Graph Name", 0, _H/2, native.systemFontBold, 18 )
	graphName:setFillColor(190/255, 190/255, 1, 1)
	graphName.x = graphName.height/2
	graphName.anchorX=0.5
	graphName.anchorY=0.5
	graphName:rotate( 90 )
	
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
		graphType = 1
		DrawNextGraph()
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
	graphDetails:removeSelf()
	fullRect:removeEventListener( "touch", HandleSwipe )
	fullRect:removeSelf()
	yAxis:removeSelf()
	xAxis:removeSelf()
	for i=1,10 do
		xTicks[i]:removeSelf()
	end
	if graphDetails then 
		graphDetails:removeSelf()
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene