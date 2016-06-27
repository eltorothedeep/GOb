local scene = composer.newScene()

local header
local qText
local aText
local wrongButton
local guessedButton
local rightButton
local endButton
local answerButton


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

function GetNextQuestion( lastResult )
	local sqlcmd = 'select * from Questions where QID = "' .. tostring( index ) .. '"'
	--print( sqlcmd )
	db:exec(sqlcmd,saveRow,'test_udata')
	for i=1,rowCols do 
		if keys[i] == 'Question' then
			qText.text = tostring( index ).. '. ' .. data[i]
			break
		end
	end
	aText.text = '...'
	
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