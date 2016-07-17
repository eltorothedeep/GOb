composer = require( "composer" )

composer.setVariable( "numQs", 20 )
composer.setVariable( "sessionScore", 0 )

composer.setVariable( "askAny", false )
composer.setVariable( "askSel", true )
composer.setVariable( "askList", "|NEW" )

composer.setVariable( "typeAny", true )
composer.setVariable( "typeSel", false )
composer.setVariable( "typeList", "" )

composer.setVariable( "continentAny", true )
composer.setVariable( "continentSel", false )
composer.setVariable( "continentList", "" )

composer.setVariable( "countryAny", true )
composer.setVariable( "countrySel", false )
composer.setVariable( "countryList", "" )

--[[ 
	
	User Database version info
	0 - Pre Attempt Time Left and Session Score
	1 - Attempt Time Left and Session Score added
	
]]
local userdata_version = 0

centerX = display.contentCenterX
centerY = display.contentCenterY
_W = display.contentWidth
_H = display.contentHeight
space = 9
buttonHeight = 40
buttonWidth = _W/3.5
bannerEnd = 53

appOriginY = display.screenOriginY + bannerEnd
appCanvasHeight = _H - appOriginY

display.setStatusBar( display.HiddenStatusBar ) 

function AddText( group, headerText, fontSize, fillColorR, fillColorG, fillColorB, fillColorA, x, y, space )
	local label1 = display.newText( group, headerText, x, y, native.systemFontBold, fontSize )
	label1:setFillColor( fillColorR, fillColorG, fillColorB, fillColorA )
	group:insert( label1 )
	return label1, y + label1.height + space
end

function AddBackground( options )
	local bkgnd = display.newRect( options.x, options.y, options.w, options.h, options.fontSize )
	if options.fill ~= nil then
		bkgnd:setFillColor( options.fill )
	end
	if options.anchorX then
		bkgnd.anchorX = options.anchorX
	end
	if options.anchorY then
		bkgnd.anchorY = options.anchorY
	end
	if options.parent then
		options.parent:insert( bkgnd )
	end
end

--Include sqlite
require "sqlite3"
widget = require( "widget" )

function PrintTable( t, l, max )
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
tempData = {}

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
sessionID = 0
userID = 0
startTime = 0

function saveRow(udata,cols,values,names)
	if udata=='test_udata' then
		keys = {}
		data = {}
		rowCols = cols
		for i=1,rowCols do 
			keys[i] = names[i]
			data[i] = values[i]
		end
	elseif udata:find( 'fetch_col' ) then
		local colName = udata:gsub( 'fetch_col|', '' )
		for i=1,cols do 
			if names[i] == colName then
				tempData[#tempData+1] = values[i]	
			end
		end
	elseif udata:find( 'user_version' ) then
		userdata_version = values[1]
	end
	return 0
end

function SetupUserDB()
	-- Open the user data database
	local path = system.pathForFile("userdata.db", system.DocumentsDirectory)
	udb = sqlite3.open( path )
	
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
	
	local checkversion = [[PRAGMA user_version]]
	udb:exec( checkversion, saveRow, 'user_version' ) 
	if userdata_version == 0 then
		print( 'Updating UserData Schema: Adding Score and TimeLeft' )
		local updateschema = [[ALTER TABLE Sessions ADD COLUMN score INTEGER ]]
		udb:exec( updateschema ) 
		updateschema = [[ALTER TABLE Attempts ADD COLUMN timeleft INTEGER ]]
		udb:exec( updateschema ) 
		updateschema = [[PRAGMA user_version = 1]]
		udb:exec( updateschema ) 
	end
end

function GetLastIndex()
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

function IncAndWriteIndex()
	index = index + 1

	local filePath = system.pathForFile( 'lastIndex.txt', system.DocumentsDirectory )
	file = io.open( filePath, "w" )
	file:write( tostring( index ) )
	io.close( file ) 
end

function OpenDatabases( fullOpen )
	-- Open the user data database
	local path = system.pathForFile("userdata.db", system.DocumentsDirectory)
	udb = sqlite3.open( path )
	
	if fullOpen then
		-- open the questions database
		local rfilePath = system.pathForFile( "GeoBeeQ.db", system.ResourceDirectory )		
		db = sqlite3.open( rfilePath )   
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

function GetQuizDBInfo( sqlcmd, colname )
	tempData = {}
	db:exec(sqlcmd,saveRow,'fetch_col|'..colname)
	dbInfo = {}
	for i=1,#tempData do
		dbInfo[i] = tempData[i]
	end
	return dbInfo
end

function WholePercent( fraction )
	return (fraction*100) - (fraction*100)%1
end

local function DeltaTime( start, endtime )
	sh, sm, ss = start:match( '(%d):(%d):(%d)' )
	eh, em, es = endtime:match( '(%d):(%d):(%d)' )
end

function EndSession( doDBops, closeUDB )
	if doDBops == nil then doDBops = true end
	if closeUDB == nil then closeUDB = false end
	
	if doDBops then
		local date = os.date( "*t" )
		local q = [[UPDATE Sessions SET endtime=']]..os.date( "%H:%M:%S" )..[[' WHERE id=']]..sessionID..[[';]]
		udb:exec( q )
		q = [[UPDATE Sessions SET length=']]..os.time()-startTime..[[' WHERE id=']]..sessionID..[[';]]
		udb:exec( q )
		q = [[UPDATE Sessions SET score=']]..composer.getVariable( "sessionScore" )..[[' WHERE id=']]..sessionID..[[';]]
		udb:exec( q )
	end
	
	if closeUDB then
		udb:close()
	end
	
	sessionID = 0
end

function StartSession()
	welcomeScreen.TransitionOut( 400 )
	local options = 
	{
		effect = "fade",
		time = 400,
	}	
	composer.gotoScene( "quizoptions", options )
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


SetupUserDB()
GetLastIndex()
OpenDatabases( true )

local options = 
{
	effect = "fade",
	time = 400,
	params = 
	{
		updateInfo = true,
	}
}
composer.gotoScene( "welcomescreen", options )

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
				q = [[UPDATE Sessions SET score=']]..composer.getVariable( "sessionScore" )..[[' WHERE id=']]..sessionID..[[';]]
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
			composer.gotoScene( "graphsscreen", options )
		else
			options.params.updateInfo = false
			composer.gotoScene( "welcomescreen", options )
		end
	end
end

local function onKeyEvent( event )
	local phase = event.phase
	local keyName = event.keyName
	--print( event.phase, event.keyName )

	if ( "back" == keyName and phase == "up" ) then
		if sessionID ~= 0 then
			EndSession(true, true)
			return true
		end
	end
end

--setup the system listener to catch applicationExit
Runtime:addEventListener( "system", onSystemEvent )
Runtime:addEventListener( "orientation", onOrientationChange )
Runtime:addEventListener( "key", onKeyEvent )
