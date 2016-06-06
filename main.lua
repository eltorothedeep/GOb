centerX = display.contentCenterX
centerY = display.contentCenterY
_W = display.contentWidth
_H = display.contentHeight
space = 9
buttonHeight = 40
buttonWidth = _W/3.5
bannerEnd = 53
appState = "startup"

appOriginY = display.screenOriginY + bannerEnd
display.setStatusBar( display.HiddenStatusBar ) 

--Include sqlite
require "sqlite3"
widget = require( "widget" )

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

rowCols = 0
keys = {}
data = {}
question=false
index = 1800

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

db = nil
udb = nil

local graphScreen = require( 'graphs' )
local welcomeScreen = require( 'welcome' )
local quizScreen = require( 'quiz' )

sessionID = 0
userID = 0
startTime = 0

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

function GetUserDB()
	return udb
end

function CloseUserDB()
	udb:close()
end

--display.setDefault( "anchorX", 0.0 )	-- default to TopLeft anchor point for new objects
--display.setDefault( "anchorY", 0.0 )

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

function GetNextQuestion( lastResult )
	local sqlcmd = 'select * from Questions where QID = "' .. tostring( index ) .. '"'
	--print( sqlcmd )
	db:exec(sqlcmd,saveRow,'test_udata')
	for i=1,rowCols do 
		if keys[i] == 'Question' then
			quizScreen.question.text = tostring( index ).. '. ' .. data[i]
			break
		end
	end
	quizScreen.answer.text = '...'
	
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

function WholePercent( fraction )
	return (fraction*100) - (fraction*100)%1
end

local function DeltaTime( start, endtime )
	sh, sm, ss = start:match( '(%d):(%d):(%d)' )
	eh, em, es = endtime:match( '(%d):(%d):(%d)' )
end

function EndSession( doDBops )
	if doDBops == nil then doDBops = true end
	
		local timeToTransition = 0
		if doDBops then
			local date = os.date( "*t" )
			local q = [[UPDATE Sessions SET endtime=']]..os.date( "%H:%M:%S" )..[[' WHERE id=']]..sessionID..[[';]]
			udb:exec( q )
			q = [[UPDATE Sessions SET length=']]..os.time()-startTime..[[' WHERE id=']]..sessionID..[[';]]
			udb:exec( q )			
			timeToTransition = 400
		end
		welcomeScreen.TransitionIn( timeToTransition, true )
		if doDBops then
			udb:close()
		end
		sessionID = 0
		
		quizScreen.TransitionOut( timeToTransition )
end

function StartSession()
	welcomeScreen.TransitionOut( 400 )
	quizScreen.TransitionIn( 400 )

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

local function onOrientationChange( event )
	if sessionID == 0 then
		if string.find( event.type, 'landscape' ) then
			welcomeScreen.TransitionOut( timeToTransition )
			graphScreen.TransitionIn()
		else
			graphScreen.TransitionOut()
			welcomeScreen.TransitionIn( timeToTransition, false )
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

local function appState(event)
	if appstate == 'startup' then
	elseif appstate == 'welcome' then
	elseif appstate == 'quiz' then
	end
end

--setup the system listener to catch applicationExit
Runtime:addEventListener( "system", onSystemEvent )
Runtime:addEventListener( "orientation", onOrientationChange )
Runtime:addEventListener( "key", onKeyEvent )
Runtime:addEventListener( "enterFrame", appState );
