local quizUI = {}
quizUI.screen = display.newGroup()

quizzing = display.newGroup()

quizUI.screen:insert( quizzing )

local label2 = display.newText( quizUI.screen, "Geo Quiz", _W/2.0, appOriginY, native.systemFontBold, 24 )
label2:setFillColor( 190/255, 190/255, 1, 1 )

quizUI.question = display.newText("", 5, 200, _W-10, 0, native.systemFont, 16)
quizUI.question.anchorX = 0
quizUI.question:setFillColor(1,1,1)

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

quizUI.answer = display.newText( aOpts )
quizUI.answer.anchorX = 0
quizUI.answer:setFillColor(1,1,1)	



local function GoToWelcome( event )
	EndSession( true )
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
			quizUI.answer.text = data[i]
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

quizzing:insert( answerButton )
quizzing:insert( rightButton )
quizzing:insert( wrongButton )
quizzing:insert( guessedButton )
quizzing:insert( endButton )
quizzing:insert( quizUI.question )
quizzing:insert( quizUI.answer )

local function StartQuizzing( event )
	OpenDatabases( false )

	local date = os.date( "*t" )    -- returns table of date & time values
	startTime = os.time()
	local newSession=[[INSERT INTO Sessions VALUES (NULL, ']]..userID..[[',']]..os.date( "%m/%d/%Y" )..[[',']]..os.date( "%H:%M:%S" )..[[', NULL, NULL); ]]
	--print( newSession )
	udb:exec( newSession )
	sessionID = udb:last_insert_rowid()
	--print( sessionID )

	GetNextQuestion( nil )

	transition.to( quizzing, { alpha=1, time = 400, transition = easing.inQuad } )

end




quizUI.TransitionIn = function(timeToTransition)
	transition.to( quizUI.screen, { alpha=1, time = timeToTransition, transition = easing.inQuad } )
end

quizUI.TransitionOut = function(timeToTransition)
	transition.to( quizUI.screen, { alpha=0, time = timeToTransition, transition = easing.outQuad } )
end

return quizUI