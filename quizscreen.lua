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

-- Data
local qNum = 0
local sessionQIDs = {}

local function GoToWelcome( event )
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
	for w in string.gmatch( varList, "|([%a.]+)") do
		for i = 1, #fieldList do
			if first then
				first = false
			else
				sqlcmd = sqlcmd .. ' OR'
			end		
			sqlcmd = sqlcmd .. ' ' .. fieldList[i] ..'  = "'..w..'"'
		end
	end
	return sqlcmd
end

function GetSessionQuestions()
	-- Clear the data
	qNum = 0
	sessionQIDs = {}
	
	local sqlcmd = 'select * from Questions'
	local firstCondition = true
	local varList = composer.getVariable( "typeList" )
	if  varList ~= "" then
		if firstCondition then
			firstCondition = false
			sqlcmd = sqlcmd .. ' WHERE'
		else
			sqlcmd = sqlcmd .. ' AND'
		end
		sqlcmd = sqlcmd .. ' ( ' .. AddCondition( varList, {'Type1', 'Type2'} ) .. ' )'
	end
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
	sqlcmd = sqlcmd .. ' LIMIT ' .. tostring( composer.getVariable( "numQs" ) )
	print( sqlcmd )
	local dbInfo = GetQuizDBInfo( sqlcmd, 'QID' )
	for i= 1, #dbInfo do
		sessionQIDs[#sessionQIDs+1] = dbInfo[i]
	end
	PrintTable( sessionQIDs, 1, 2 )

--SELECT * FROM DBOne.dbo.Table1 AS t1 INNER JOIN DBTwo.dbo.Table2 t2 ON t2.ID = t1.ID
--SELECT Questions.qid FROM Questions JOIN Attempts ON Questions.QID = Attempts.qid WHERE Attempts.result = "MISSED" OR Attempts.result = "GUESSED"
end

function GetNextQuestion( lastResult )
	-- Write info about the attempt
	if lastResult then
		local newAttempt=[[INSERT INTO Attempts VALUES (NULL, ']]..userID..[[',']]..sessionID..[[',']].. sessionQIDs[qNum]..[[',']]..lastResult..[['); ]]
		udb:exec( newAttempt )
	end
	-- Get next question of exit if session ended
	qNum = qNum + 1
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
		aText.text = '...'
	else
		GoToWelcome( nil )
	end
	--IncAndWriteIndex()
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
	GetNextQuestion( event.target.id )
end

local function showAnswer()
	for i=1,rowCols do 
		if keys[i] == 'Answer' then
			aText.text = data[i]
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

-- Composer API
function scene:create( event )
    local sceneGroup = self.view
	
	local nextTop 
	header, nextTop = AddText( sceneGroup, "Geo Quiz", 24, 190/255, 190/255, 1, 1, _W/2.0, appOriginY, 0 );
	qText = display.newText("", 5, 200, _W-10, 0, native.systemFont, 16)
	qText.anchorX = 0
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
		fontSize = 18,
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
		OpenDatabases( false )

		local date = os.date( "*t" )    -- returns table of date & time values
		startTime = os.time()
		local newSession=[[INSERT INTO Sessions VALUES (NULL, ']]..userID..[[',']]..os.date( "%m/%d/%Y" )..[[',']]..os.date( "%H:%M:%S" )..[[', NULL, NULL); ]]
		--print( newSession )
		udb:exec( newSession )
		sessionID = udb:last_insert_rowid()
		--print( sessionID )

		GetSessionQuestions()
		GetNextQuestion( nil )
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
	
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene