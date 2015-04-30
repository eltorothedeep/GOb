local centerX = display.contentCenterX
local centerY = display.contentCenterY
local _W = display.contentWidth
local _H = display.contentHeight
local space = 9
local buttonHeight = 40
local buttonWidth = _W/3.5
bannerEnd = 53
appOriginY = display.screenOriginY + bannerEnd
display.setStatusBar( display.HiddenStatusBar ) 

local function PrintTable( t, l, max )
	for k,v in pairs( t ) do
		if l < max then
			if type( v ) == 'table' then
				l = l + 1
				print( string.rep( '\t', l ) .. k )
				PrintTable(v, l, max)
				l = l - 1
			end
		end
		print( string.rep( '\t', l ), k, v )
	end	
end

--Include sqlite
require "sqlite3"
local widget = require( "widget" )

local rowCols = 0
local keys = {}
local data = {}
local question=false
local index = 800

local graphType = 1
theme = 
{
	{
		id = "ATTEMPTS",
		Color = { 1, 1, 1, 1 },
	},
	{
		id = "MISSED",
		Color = { 1, 0.3, 0.3, 1 },
	},
	{
		id = "GUESSED",
		Color = { 1, 0.85, 0.3, 1 },
	},
	{
		id = "CORRECT",
		Color = { 0.3, 0.85, 0.3, 1 },
	},
}

local db
local udb

local sessionID = 0
local userID = 0
local startTime = 0

function OpenDatabases( fullOpen )
	-- Open the user data database
	local path = system.pathForFile("userdata.db", system.DocumentsDirectory)
	udb = sqlite3.open( path )
	
	if fullOpen then
		-- open the questions database
		local rfilePath = system.pathForFile( "GeoBeeQ.db", system.ResourceDirectory )		
		db = sqlite3.open( rfilePath )   
		
		-- Setup the user data database
		local tablesetup = [[CREATE TABLE IF NOT EXISTS Users (id INTEGER PRIMARY KEY, username TEXT);]]
		--print(tablesetup)
		udb:exec( tablesetup )
		tablesetup = [[CREATE TABLE IF NOT EXISTS Sessions(id INTEGER PRIMARY KEY, userid INTEGER, date TEXT, starttime TEXT, endtime TEXT, length INTEGER);]]
		--print(tablesetup)
		udb:exec( tablesetup )
		tablesetup = [[CREATE TABLE IF NOT EXISTS Attempts (id INTEGER PRIMARY KEY, userid INTEGER, sessionid INTEGER, qid INTEGER, result TEXT);]]
		--print(tablesetup)
		udb:exec( tablesetup )

		for row in udb:nrows("SELECT * FROM Users WHERE username='Durga';") do
			userID = row.id
			--print( sessionID )
		end
		if userID == 0 then
			local tablefill =[[INSERT INTO Users VALUES (NULL, 'Durga'); ]]
			udb:exec( tablefill )
		end
		for row in udb:nrows("SELECT * FROM Users WHERE username='Durga';") do
			userID = row.id
			--print( sessionID )
		end
		
		local filePath = system.pathForFile( 'lastIndex.txt', system.DocumentsDirectory )
		if filePath then
			file = io.open( filePath, "r" )
			if file then
				for line in file:lines() do
					index = tonumber( line )
					break
				end
				io.close( file )
			end
		end
	end
end

local welcomeScreen = display.newGroup()
local quizScreen = display.newGroup()
local graphScreen = display.newGroup()
local fullRect = display.newRect( graphScreen, _W/2,_H/2,_W,_H )
fullRect:setFillColor(190/255, 190/255, 1, 0.5)
local yAxis = display.newLine( graphScreen, 0, 30, _W, 30 )
local xAxis = display.newLine( graphScreen, 30, 0, 30, _H )
xAxis.strokeWidth = 2
yAxis.strokeWidth = 2
local tickDist = ( _H-60 ) / 11
for i=1,10 do
	display.newLine( graphScreen, 25, 30+(i*tickDist), 35, 30+(i*tickDist) )
end
local graphName = display.newText( graphScreen, "Graph Name", 0, _H/2, native.systemFontBold, 18 )
graphName:setFillColor(190/255, 190/255, 1, 1)
graphName.x = graphName.height/2
graphName.anchorX=0.5
graphName.anchorY=0.5
graphName:rotate( 90 )
transition.to( graphScreen, { alpha=0, time = 0, transition = easing.outQuad } )

--display.setDefault( "anchorX", 0.0 )	-- default to TopLeft anchor point for new objects
--display.setDefault( "anchorY", 0.0 )

-- Add onscreen text
local label1 = display.newText( welcomeScreen, "Geo Quiz", _W/2.0, appOriginY, native.systemFontBold, 24 )
label1:setFillColor( 190/255, 190/255, 1, 1 )

local label2 = display.newText( quizScreen, "Geo Quiz", _W/2.0, appOriginY, native.systemFontBold, 24 )
label2:setFillColor( 190/255, 190/255, 1, 1 )

nextTop = appOriginY + label1.height-- + space
local cumStats = display.newText( welcomeScreen, "Cumulative Stats:", space, nextTop, native.systemFontBold, 16 )
cumStats.anchorX = 0
cumStats.anchorY = 0
nextTop = nextTop + cumStats.height
display.newLine( welcomeScreen, space, nextTop, cumStats.width*1.1, nextTop )

local cumStatInfoLabels = {}
local cumStatInfoValues = {}
nextTop = nextTop + space
for i=1,#theme do
	cumStatInfoLabels[i] = display.newText( welcomeScreen, theme[i].id..": ", space, nextTop, native.systemFontBold, 16 )
	cumStatInfoLabels[i].anchorX = 0
	cumStatInfoLabels[i].anchorY = 0
	cumStatInfoLabels[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )

	cumStatInfoValues[i] = display.newText( welcomeScreen, "", _W/2, nextTop, native.systemFontBold, 16 )
	cumStatInfoValues[i].anchorX = 0
	cumStatInfoValues[i].anchorY = 0
	cumStatInfoValues[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )
	
	nextTop = nextTop + cumStatInfoValues[i].height + space
end

nextTop = nextTop + space
local lastStats = display.newText( welcomeScreen, "Last Session Stats:", space, nextTop, native.systemFontBold, 16 )
lastStats.anchorX = 0
lastStats.anchorY = 0
nextTop = nextTop + lastStats.height
display.newLine( welcomeScreen, space, nextTop, lastStats.width*1.1, nextTop )

nextTop = nextTop + space
local lTimeL = display.newText( welcomeScreen, "Total Time: ", space, nextTop, native.systemFontBold, 16 )
local lTimeV = display.newText( welcomeScreen, "", _W/2, nextTop, native.systemFontBold, 16 )
lTimeL.anchorX = 0
lTimeL.anchorY = 0
lTimeV.anchorX = 0
lTimeV.anchorY = 0
lTimeL:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
lTimeV:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])

nextTop = nextTop + lTimeV.height + space
local lSpeedL = display.newText( welcomeScreen, "Time/Question: ", space, nextTop, native.systemFontBold, 16 )
local lSpeedV = display.newText( welcomeScreen, "", _W/2, nextTop, native.systemFontBold, 16 )
lSpeedL.anchorX = 0
lSpeedL.anchorY = 0
lSpeedV.anchorX = 0
lSpeedV.anchorY = 0
lSpeedL:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
lSpeedV:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])

nextTop = nextTop + lSpeedL.height + space
local lastStatInfoLabels = {}
local lastStatInfoValues = {}
for i=1,#theme do
	lastStatInfoLabels[i] = display.newText( welcomeScreen, theme[i].id..": ", space, nextTop, native.systemFontBold, 16 )
	lastStatInfoLabels[i].anchorX = 0
	lastStatInfoLabels[i].anchorY = 0
	lastStatInfoLabels[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )

	lastStatInfoValues[i] = display.newText( welcomeScreen, "", _W/2, nextTop, native.systemFontBold, 16 )
	lastStatInfoValues[i].anchorX = 0
	lastStatInfoValues[i].anchorY = 0
	lastStatInfoValues[i]:setFillColor( theme[i].Color[1], theme[i].Color[2], theme[i].Color[3], theme[i].Color[4] )
	
	nextTop = nextTop + lastStatInfoValues[i].height + space
end


--~ local lAttemptsL = display.newText( welcomeScreen, "Last Attempts: ", space, nextTop, native.systemFontBold, 16 )
--~ local lAttemptsV = display.newText( welcomeScreen, "", _W/2, nextTop, native.systemFontBold, 16 )
--~ lAttemptsL.anchorX = 0
--~ lAttemptsL.anchorY = 0
--~ lAttemptsV.anchorX = 0
--~ lAttemptsV.anchorY = 0
--~ lAttemptsL:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
--~ lAttemptsV:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])

--~ graphType = graphType + 1
--~ nextTop = nextTop + lAttemptsL.height + space
--~ local lMissedL = display.newText( welcomeScreen, "Last Missed: ", space, nextTop, native.systemFontBold, 16 )
--~ local lMissedV = display.newText( welcomeScreen, "", _W/2, nextTop, native.systemFontBold, 16 )
--~ lMissedL.anchorX = 0
--~ lMissedL.anchorY = 0
--~ lMissedV.anchorX = 0
--~ lMissedV.anchorY = 0
--~ lMissedL:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
--~ lMissedV:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])

--~ graphType = graphType + 1
--~ nextTop = nextTop + lMissedL.height + space
--~ local lGuessedL = display.newText( welcomeScreen, "Last Guessed: ", space, nextTop, native.systemFontBold, 16 )
--~ local lGuessedV = display.newText( welcomeScreen, "", _W/2, nextTop, native.systemFontBold, 16 )
--~ lGuessedL.anchorX = 0
--~ lGuessedL.anchorY = 0
--~ lGuessedV.anchorX = 0
--~ lGuessedV.anchorY = 0
--~ lGuessedL:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
--~ lGuessedV:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])

--~ graphType = graphType + 1
--~ nextTop = nextTop + lGuessedL.height + space
--~ local lCorrectL = display.newText( welcomeScreen, "Last Correct: ", space, nextTop, native.systemFontBold, 16 )
--~ local lCorrectV = display.newText( welcomeScreen, "", _W/2, nextTop, native.systemFontBold, 16 )
--~ lCorrectL.anchorX = 0
--~ lCorrectL.anchorY = 0
--~ lCorrectV.anchorX = 0
--~ lCorrectV.anchorY = 0
--~ lCorrectL:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])
--~ lCorrectV:setFillColor( theme[graphType].Color[1], theme[graphType].Color[2], theme[graphType].Color[3], theme[graphType].Color[4])


local q = display.newText("", 5, 200, _W-10, 0, native.systemFont, 16)
q.anchorX = 0
q:setFillColor(1,1,1)

local aOpts = 
{
	parent = quizScreen,
	text = "",
	x = 5,
	y = 350,
	width = _W-10,
	height = 0,
	font = native.systemFont,
	fontSize = 18,
	align = 'center',
}

local a = display.newText( aOpts )
a.anchorX = 0
a:setFillColor(1,1,1)

function saveRow(udata,cols,values,names)
	--print( udata, cols )
	if udata=='test_udata' then
		keys = {}
		data = {}
		rowCols = cols
		for i=1,rowCols do 
			keys[i] = names[i]
			data[i] = values[i]
		end
--	elseif udata=='countattempts' then
	end
	return 0
end

local function GetNextQuestion( lastResult )
	local sqlcmd = 'select * from Questions where QID = "' .. tostring( index ) .. '"'
	--print( sqlcmd )
	db:exec(sqlcmd,saveRow,'test_udata')
	for i=1,rowCols do 
		if keys[i] == 'Question' then
			q.text = tostring( index ).. '. ' .. data[i]
			break
		end
	end
	a.text = '...'
	
	if lastResult then
		local newAttempt=[[INSERT INTO Attempts VALUES (NULL, ']]..userID..[[',']]..sessionID..[[',']]..index..[[',']]..lastResult..[['); ]]
		udb:exec( newAttempt )
	end
	
	index = index + 1

	local filePath = system.pathForFile( 'lastIndex.txt', system.DocumentsDirectory )
	file = io.open( filePath, "w" )
	file:write( tostring( index ) )
	io.close( file ) 
end

local function WholePercent( fraction )
	return (fraction*100) - (fraction*100)%1
end

local function DeltaTime( start, endtime )
	sh, sm, ss = start:match( '(%d):(%d):(%d)' )
	eh, em, es = endtime:match( '(%d):(%d):(%d)' )
end

local function EndSession( doDBops )
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
		
		local timeToTransition = 0
		if doDBops then
			local date = os.date( "*t" )
			local q = [[UPDATE Sessions SET endtime=']]..os.date( "%H:%M:%S" )..[[' WHERE id=']]..sessionID..[[';]]
			udb:exec( q )
			q = [[UPDATE Sessions SET length=']]..os.time()-startTime..[[' WHERE id=']]..sessionID..[[';]]
			udb:exec( q )			
			timeToTransition = 400
		end
		if sessionID == 0 then
			for x in udb:urows "SELECT COUNT(*) FROM Sessions;" do 
				sessionID = x
			end			
		end
		print( sessionID )
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
		if doDBops then
			udb:close()
		end
		sessionID = 0
		
		transition.to( quizScreen, { alpha=0, time = timeToTransition, transition = easing.outQuad } )
		transition.to( welcomeScreen, { alpha=1, time = timeToTransition, transition = easing.outExpo } )	
end

local function StartSession()
	transition.to( welcomeScreen, { alpha=0, time = 400, transition = easing.outQuad } )
	transition.to( quizScreen, { alpha=1, time = 400, transition = easing.outExpo } )	

	OpenDatabases( false )

	local date = os.date( "*t" )    -- returns table of date & time values
	startTime = os.time()
	local newSession=[[INSERT INTO Sessions VALUES (NULL, ']]..userID..[[',']]..os.date( "%m/%d/%Y" )..[[',']]..os.date( "%H:%M:%S" )..[[', NULL, NULL); ]]
	--print( newSession )
	udb:exec( newSession )
	sessionID = udb:last_insert_rowid()
	--print( sessionID )

	GetNextQuestion( nil )
end

local function StartOrEndSession( event )
	if event.target.id == 'START' then
		StartSession()
	else
		EndSession( true )
	end
end

local function onSendEmail( event )
	-- compose an HTML email with two attachments
	local options =
	{
	   to = { "sandeep.kharkar@gmail.com" },
	   --cc = { "john.smith@somewhere.com", "jane.smith@somewhere.com" },
	   subject = "GOb",
	   isBodyHtml = true,
	   body = "<html><body>Current User Database</body></html>",
	   attachment =
	   {
		  { baseDir=system.ResourceDirectory, filename="userdata.db", type="binary" },
	   },
	}
	local result = native.showPopup("mail", options)
	
	if not result then
		print( "Mail Not supported/setup on this device" )
		native.showAlert( "Alert!",
		"Mail not supported/setup on this device.", { "OK" }
	);
	end
	-- NOTE: options table (and all child properties) are optional
end

endButton = widget.newButton
{
	id = "END",
	label = "End Session", 
    emboss = false,
	shape="roundedRect",
	width = _W*.8,
	height = buttonHeight*.75,
    cornerRadius = 10,
    labelColor = { default={ 1, 0.3, 0.3, 1 }, over={ .1, 0.1, 0.1, 1 } },
    fillColor = { default={ 0,0,0, 1 }, over={ 1, 1, 1, 0.6 } },
    strokeColor = { default={ 190/255, 190/255, 1, 1 }, over={ 0, 0, 0, 1 } },
    strokeWidth = 5,	
	onRelease = StartOrEndSession
}
endButton.x = display.contentWidth * 0.5
endButton.y = appOriginY + 50

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
	onRelease = StartOrEndSession
}
startButton.anchorX = 0.5
startButton.anchorY = 0.5
startButton.x = display.contentWidth * 0.5
startButton.y = _H - ( buttonHeight )
welcomeScreen:insert( startButton )

local function nextQuestion( event )
	GetNextQuestion( event.target.id )
	answerButton.alpha = 1.0
	answerButton:setEnabled( true )
	wrongButton.alpha = 0
	wrongButton:setEnabled( false )
	guessedButton.alpha = 0
	guessedButton:setEnabled( false )
	rightButton.alpha = 0
	rightButton:setEnabled( false )
end

local function showAnswer()
	for i=1,rowCols do 
		if keys[i] == 'Answer' then
			a.text = data[i]
			break
		end
	end
	answerButton.alpha = 0
	answerButton:setEnabled( false )
	wrongButton.alpha = 1.0
	wrongButton:setEnabled( true )
	guessedButton.alpha = 1.0
	guessedButton:setEnabled( true )
	rightButton.alpha = 1.0
	rightButton:setEnabled( true )
end

--Create the edit button
answerButton = widget.newButton
{
	label = "Show Answer", 
    emboss = false,
	shape="roundedRect",
	width = display.contentWidth/2,
	height = buttonHeight,
    cornerRadius = 10,
    labelColor = { default={ 1, 1, 1, 1 }, over={ .1, 0.1, 0.1, 1 } },
    fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
    strokeColor = { default={ 190/255, 190/255, 1, 1 }, over={ 0, 0, 0, 1 } },
    strokeWidth = 5,	
	onRelease = showAnswer,
}
answerButton.alpha = 1
answerButton.x = display.contentWidth * 0.5
answerButton.y = display.contentHeight - buttonHeight * 1.5

wrongButton = widget.newButton
{
	id = theme[2].id,
	label = "Missed", 
    emboss = false,
	shape="roundedRect",
	width = buttonWidth,
	height = buttonHeight,
    cornerRadius = 10,
    labelColor = { default={ 1, 1, 1, 1 }, over={ .1, 0.1, 0.1, 1 } },
    fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
    strokeColor = { default=theme[2].Color, over={ 0, 0, 0, 1 } },
    strokeWidth = 5,	
	onRelease = nextQuestion
}
wrongButton.alpha = 0
wrongButton:setEnabled( false )
wrongButton.x = display.contentWidth *.17
wrongButton.y = display.contentHeight - buttonHeight * 1.5

guessedButton = widget.newButton
{
	id = theme[3].id,
	label = "Guessed", 
    emboss = false,
	shape="roundedRect",
	anchorX = 0.5,
	width = buttonWidth,
	height = buttonHeight,
    cornerRadius = 10,
    labelColor = { default={ 1, 1, 1, 1 }, over={ .1, 0.1, 0.1, 1 } },
    fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
    strokeColor = { default=theme[3].Color, over={ 0, 0, 0, 1 } },
    strokeWidth = 5,	
	onRelease = nextQuestion
}
guessedButton.alpha = 0
guessedButton:setEnabled( false )
guessedButton.x = display.contentWidth * 0.5
guessedButton.y = display.contentHeight - buttonHeight * 1.5

rightButton = widget.newButton
{
	id = theme[4].id,
	label = "Got It!", 
    emboss = false,
	shape="roundedRect",
	anchorX = 0.5,
	width = buttonWidth,
	height = buttonHeight,
    cornerRadius = 10,
    labelColor = { default={ 1, 1, 1, 1 }, over={ .1, 0.1, 0.1, 1 } },
    fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
    strokeColor = { default=theme[4].Color, over={ 0, 0, 0, 1 } },
    strokeWidth = 5,	
	onRelease = nextQuestion
}
rightButton.alpha = 0
rightButton:setEnabled( false )
rightButton.x = display.contentWidth * 0.83
rightButton.y = display.contentHeight - buttonHeight * 1.5

quizScreen:insert( answerButton )
quizScreen:insert( rightButton )
quizScreen:insert( wrongButton )
quizScreen:insert( guessedButton )
quizScreen:insert( endButton )
quizScreen:insert( q )
quizScreen:insert( a )

OpenDatabases( true )
EndSession( false )

--Handle the applicationExit event to close the db
local function onSystemEvent( event )
	if( event.type == "applicationExit" ) then              
		db:close()
		if udb:isopen() then
			if sessionID ~= 0 then
				local date = os.date( "*t" )
				local q = [[UPDATE Sessions SET endtime=']]..os.date( "%H:%M:%S" )..[[' WHERE id=']]..sessionID..[[';]]
				udb:exec( q )
				q = [[UPDATE Sessions SET length=']]..os.time()-startTime..[[' WHERE id=']]..sessionID..[[';]]
				udb:exec( q )			
				sessionID = 0
			end
			udb:close()
		end

		local filePath = system.pathForFile( 'lastIndex.txt', system.DocumentsDirectory )
		file = io.open( filePath, "w" )
		file:write( tostring( index ) )
		io.close( file ) 

	end
end

local graphDetails

local function DrawGraph()
	OpenDatabases( false )
	graphDetails = display.newGroup()
	graphScreen:insert( graphDetails )
	local maxSessions
	for x in udb:urows "SELECT COUNT(*) FROM Sessions;" do 
		maxSessions = x
	end
	local graphData = {}
	local minVal = 10000000
	local maxVal = -1
	while #graphData<10 and maxSessions-#graphData>0 do
		local query = [[SELECT COUNT(*) FROM Attempts WHERE sessionid=]] .. maxSessions-#graphData .. [[ ;]]
		local numAttempts
		for x in udb:urows(query) do 
			numAttempts = x
		end
		if graphType == 1 then
			graphData[#graphData+1] = numAttempts
			if numAttempts<minVal then minVal=numAttempts end 
			if numAttempts>maxVal then maxVal=numAttempts end
		else
			query = "SELECT COUNT(*) FROM Attempts WHERE sessionid=" .. maxSessions-#graphData .. " AND result='" .. theme[graphType].id .. "';"
			for x in udb:urows(query) do 
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
	udb:close()
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

fullRect:addEventListener( "touch", HandleSwipe )

local function onOrientationChange( event )
	if sessionID == 0 then
		if string.find( event.type, 'landscape' ) then
			transition.to( welcomeScreen, { alpha=0, time = timeToTransition, transition = easing.outQuad } )
			transition.to( graphScreen, { alpha=1, time = timeToTransition, transition = easing.outExpo } )	
			graphType = 1
			DrawNextGraph()
		else
			if graphDetails then
				graphDetails:removeSelf()
			end
			transition.to( graphScreen, { alpha=0, time = timeToTransition, transition = easing.outQuad } )
			transition.to( welcomeScreen, { alpha=1, time = timeToTransition, transition = easing.outExpo } )	
		end
	end
end

local function onKeyEvent( event )
	local phase = event.phase
	local keyName = event.keyName
	--print( event.phase, event.keyName )

	if ( "back" == keyName and phase == "up" ) then
		if sessionID ~= 0 then
			EndSession(true)
			return true
		end
	end
end

--setup the system listener to catch applicationExit
Runtime:addEventListener( "system", onSystemEvent )
Runtime:addEventListener( "orientation", onOrientationChange )
Runtime:addEventListener( "key", onKeyEvent )