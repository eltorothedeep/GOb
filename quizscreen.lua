local scene = composer.newScene()

-- Scene Controls
local header
local qText
local aText
local wrongButton
local guessedButton
local rightButton
local endButton
local answerButton
local scoreText
local qIndexText

-- Data
local maxTime = 20
local qNum = 0
local sessionQIDs = {}
local timeLeft = maxTime
local timerhandle = nil
local sessionScore = 0

local function GoToWelcome( event )
	timer.cancel ( timerHandle )
	EndSession( true, false )
	local options = 
	{
		effect = "fade",
		time = 400,
		params = 
		{
			updateInfo = true,
		},
	}	
	composer.gotoScene( "welcomescreen", options )
end

-- DB operations
function AddCondition( varList, fieldList )
	local sqlcmd = ""
	local first = true
	for w in string.gmatch( varList, '|([%a.]+)') do
		for i = 1, #fieldList do
			if first then
				first = false
			else
				sqlcmd = sqlcmd .. ' OR'
			end		
			if w == 'NULL' then
				sqlcmd = sqlcmd .. ' ' .. fieldList[i] ..' IS NULL'
			else
				sqlcmd = sqlcmd .. ' ' .. fieldList[i] ..'  = "'..w..'"'
			end
		end
	end
	return sqlcmd
end

function GetSessionQuestions()
	-- Clear the data
	qNum = 0
	sessionQIDs = {}
	
	local firstCondition = true
	local udbAttached = false
	local sqlcmd = 'select * from Questions'
	-- Question Types
	local varList = composer.getVariable( "askList" )
	if varList ~= "" then
		udbAttached = true
		CloseUserDB()
		local path = system.pathForFile("userdata.db", system.DocumentsDirectory)
		local attachCmd = "ATTACH DATABASE '" .. path .. "' AS 'userdata'"
		db:exec( attachCmd )
		
		if varList:find( '|NEW' ) ~= nil then
			varList = varList:gsub( '|NEW', '|NULL' )
			sqlcmd = sqlcmd .. ' LEFT OUTER JOIN Attempts ON Questions.QID = Attempts.qid'
		else
			sqlcmd = sqlcmd .. ' JOIN Attempts ON Questions.QID = Attempts.qid'
		end
		local conditionList = AddCondition( varList, {'Attempts.result'} ) 
		if conditionList ~= "" then
			if firstCondition then
				firstCondition = false
				sqlcmd = sqlcmd .. ' WHERE'
			else
				sqlcmd = sqlcmd .. ' AND'
			end
			sqlcmd = sqlcmd .. ' ( ' .. conditionList .. ' )'
		end
	end
	-- Types
	varList = composer.getVariable( "typeList" )
	if  varList ~= "" then
		if firstCondition then
			firstCondition = false
			sqlcmd = sqlcmd .. ' WHERE'
		else
			sqlcmd = sqlcmd .. ' AND'
		end
		sqlcmd = sqlcmd .. ' ( ' .. AddCondition( varList, {'Type1', 'Type2'} ) .. ' )'
	end
	-- Continents
	varList = composer.getVariable( "continentList" )
	if  varList ~= "" then
		if firstCondition then
			firstCondition = false
			sqlcmd = sqlcmd .. ' WHERE'
		else
			sqlcmd = sqlcmd .. ' AND'
		end
		sqlcmd = sqlcmd ..  ' ( ' .. AddCondition( varList, {'Continent'} ) .. ' )'
	end
	--Countries
	varList = composer.getVariable( "countryList" )
	if  varList ~= "" then
		if firstCondition then
			firstCondition = false
			sqlcmd = sqlcmd .. ' WHERE'
		else
			sqlcmd = sqlcmd .. ' AND'
		end
		sqlcmd = sqlcmd ..  ' ( ' .. AddCondition( varList, {'Country'} ) .. ' )'
	end
	sqlcmd = sqlcmd .. ' ORDER BY RANDOM()'
	-- Number of Questions
	sqlcmd = sqlcmd .. ' LIMIT ' .. tostring( composer.getVariable( "numQs" ) )
	local dbInfo = GetQuizDBInfo( sqlcmd, 'QID' )
	for i= 1, #dbInfo do
		sessionQIDs[#sessionQIDs+1] = dbInfo[i]
	end
--~ 	print( sqlcmd )
--~ 	PrintTable( sessionQIDs, 1, 2 )
	
	if udbAttached then
		local detachCmd = "DETACH DATABASE 'userdata'"
		db:exec( detachCmd )
		OpenDatabases( false )
	end
end

local function showAnswer( event, showMissed, showGuessed, showRight )
	timer.cancel( timerHandle )
	aText:setFillColor( 1,1,1,1 )
	for i=1,rowCols do 
		if keys[i] == 'Answer' then
			aText.text = data[i]
			break
		end
	end
	answerButton.alpha = 0
	answerButton:setEnabled( false )
	
	if showMissed == nil or showMissed == true then
		wrongButton.alpha = 1.0
		wrongButton:setEnabled( true )
	end

	if showGuessed == nil or showGuessed == true then
		guessedButton.alpha = 1.0
		guessedButton:setEnabled( true )
	end
	
	if showRight == nil or showRight == true then
		rightButton.alpha = 1.0
		rightButton:setEnabled( true )
	end
end

function TickDownTime( event )
	timeLeft = timeLeft - 1
	if timeLeft == 0 then
		showAnswer( nil, true, false, false )
	else
		aText.text = tostring( timeLeft )
		if timeLeft > maxTime-5 then
			aText:setFillColor( 0,1,0,1 )
		elseif timeLeft <= 5 then
			aText:setFillColor( 1,0,0,1 )
		else
			aText:setFillColor( 1,1,1,1 )
		end
	end
end

function GetNextQuestion( lastResult )
	-- Write info about the attempt
	if lastResult then
		-- Calculate Score and add to sessionScore
		scoreTime = math.min( timeLeft, 10 )
		scoreValue = 0
		if lastResult == 'CORRECT' then
			scoreValue = 100
		elseif lastResult == 'GUESSED' then
			scoreValue = 50
		end
		sessionScore = sessionScore + scoreTime * scoreValue
		composer.setVariable( "sessionScore", sessionScore )
		scoreText.text = tostring( sessionScore ) .. '/' .. tostring( qNum * 1000 )

		local newAttempt=[[INSERT INTO Attempts VALUES (NULL, ']]..userID..[[',']]..sessionID..[[',']].. sessionQIDs[qNum]..[[',']]..lastResult..[[',']]..timeLeft..[['); ]]
		udb:exec( newAttempt )
	end
	
		-- reset the time
	timeLeft = maxTime
	aText:setFillColor( 0,1,0,1 )
	
	-- Get next question of exit if session ended
	qNum = qNum + 1
	qIndexText.text = 'Question ' .. qNum .. ' of ' .. #sessionQIDs
	if qNum <= #sessionQIDs then
		local sqlcmd = 'select * from Questions where QID = "' .. tostring( sessionQIDs[qNum] ) .. '"'
		--print( sqlcmd )
		db:exec(sqlcmd,saveRow,'test_udata')
		for i=1,rowCols do 
			if keys[i] == 'Question' then
				qText.text = tostring(  sessionQIDs[qNum] ).. '. ' .. data[i]
				break
			end
		end
		aText.text = tostring( timeLeft )
		timerHandle = timer.performWithDelay( 1000, TickDownTime, maxTime )
	else
		GoToWelcome( nil )
	end
end

-- UI Responders
local function nextQuestion( event )
	answerButton.alpha = 1.0
	answerButton:setEnabled( true )
	wrongButton.alpha = 0
	wrongButton:setEnabled( false )
	guessedButton.alpha = 0
	guessedButton:setEnabled( false )
	rightButton.alpha = 0
	rightButton:setEnabled( false )
	if event == nil then
		GetNextQuestion( nil )
	else
		GetNextQuestion( event.target.id )
	end
end

-- Composer API
function scene:create( event )
    local sceneGroup = self.view
	
	local nextTop 
	header, nextTop = AddText( sceneGroup, "Geo Quiz", 24, 190/255, 190/255, 1, 1, _W/2.0, appOriginY, 0 );
	qIndexText = AddText( sceneGroup, "Question X of Y", 14, 190/255, 190/255, 1, 1, _W/4, 160, 0 );
	scoreText = AddText( sceneGroup, "0", 14, 190/255, 190/255, 1, 1, _W*.75, 160, 0 );
	qText = display.newText("", 5, 200, _W-10, 0, native.systemFont, 16)
	qText.anchorX = 0
	qText.anchorY = 0
	qText:setFillColor(1,1,1)
	sceneGroup:insert(qText)
	aText = display.newText( {
		parent = quizScreen,
		text = "",
		x = 5,
		y = 350,
		width = _W-10,
		height = 0,
		font = native.systemFont,
		fontSize = 24,
		align = 'center',
	} )
	aText.anchorX = 0
	aText:setFillColor(1,1,1)	
	
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
		onRelease = GoToWelcome
	}
	endButton.x = display.contentWidth * 0.5
	endButton.y = appOriginY + 50

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
		id = theme[3].id,
		label = "Missed", 
		emboss = false,
		shape="roundedRect",
		width = buttonWidth,
		height = buttonHeight,
		cornerRadius = 10,
		labelColor = { default={ 1, 1, 1, 1 }, over={ .1, 0.1, 0.1, 1 } },
		fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
		strokeColor = { default=theme[3].Color, over={ 0, 0, 0, 1 } },
		strokeWidth = 5,	
		onRelease = nextQuestion
	}
	wrongButton.alpha = 0
	wrongButton:setEnabled( false )
	wrongButton.x = display.contentWidth *.17
	wrongButton.y = display.contentHeight - buttonHeight * 1.5

	guessedButton = widget.newButton
	{
		id = theme[4].id,
		label = "Guessed", 
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
	guessedButton.alpha = 0
	guessedButton:setEnabled( false )
	guessedButton.x = display.contentWidth * 0.5
	guessedButton.y = display.contentHeight - buttonHeight * 1.5

	rightButton = widget.newButton
	{
		id = theme[5].id,
		label = "Got It!", 
		emboss = false,
		shape="roundedRect",
		anchorX = 0.5,
		width = buttonWidth,
		height = buttonHeight,
		cornerRadius = 10,
		labelColor = { default={ 1, 1, 1, 1 }, over={ .1, 0.1, 0.1, 1 } },
		fillColor = { default={ 1, 1, 1, 0.6 }, over={ 1, 1, 1, 0.6 } },
		strokeColor = { default=theme[5].Color, over={ 0, 0, 0, 1 } },
		strokeWidth = 5,	
		onRelease = nextQuestion
	}
	rightButton.alpha = 0
	rightButton:setEnabled( false )
	rightButton.x = display.contentWidth * 0.83
	rightButton.y = display.contentHeight - buttonHeight * 1.5

	sceneGroup:insert( answerButton )
	sceneGroup:insert( rightButton )
	sceneGroup:insert( wrongButton )
	sceneGroup:insert( guessedButton )
	sceneGroup:insert( endButton )
	sceneGroup:insert( qText )
	sceneGroup:insert( aText )
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
		-- reset session score
		sessionScore = 0
		composer.setVariable( "sessionScore", sessionScore )
		
		OpenDatabases( false )

		local date = os.date( "*t" )    -- returns table of date & time values
		startTime = os.time()
		local newSession=[[INSERT INTO Sessions VALUES (NULL, ']]..userID..[[',']]..os.date( "%m/%d/%Y" )..[[',']]..os.date( "%H:%M:%S" )..[[', NULL, NULL, 0); ]]
		--print( newSession )
		udb:exec( newSession )
		sessionID = udb:last_insert_rowid()
		--print( sessionID )

		GetSessionQuestions()
		nextQuestion( nil )		
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
	qText:removeSelf()
	aText:removeSelf()
	wrongButton:removeSelf()
	guessedButton:removeSelf()
	rightButton:removeSelf()
	endButton:removeSelf()
	answerButton:removeSelf()
	scoreText:removeSelf()
	qIndexText:removeSelf()
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene