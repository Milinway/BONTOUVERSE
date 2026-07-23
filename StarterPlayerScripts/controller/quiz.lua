-- StarterPlayer > StarterCharacterScripts > controller(Folder) > quiz(LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local QuizManager = {}

-- State
local currentQuestionIndex = 1
local currentData = {}
local score = 0
local answering = false
local quizGui = nil
local quizId = nil

-- Get PlayerGui
local function getPlayerGui()
	local player = Players.LocalPlayer
	return player and player:WaitForChild("PlayerGui") or nil
end

-- Fade UI
local function fadeUI(mode, callback, duration)
	duration = duration or 0.5

	local playerGui = getPlayerGui()
	if not playerGui then return end

	local uiFade = playerGui:FindFirstChild("ui_fade")
	if not uiFade then return end

	local frame = uiFade:FindFirstChild("FadeFrame")
	if not frame then return end

	uiFade.Enabled = true
	frame.Visible = true

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tween

	if mode == "in" then
		frame.BackgroundTransparency = 0
		tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 1})
	elseif mode == "out" then
		frame.BackgroundTransparency = 1
		tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0})
	end

	if tween then
		tween:Play()
		tween.Completed:Wait()
		if mode == "in" then
			uiFade.Enabled = false
			frame.Visible = false
		end
		if callback then callback() end
	else
		if callback then callback() end
	end
end

-- Slide Frame
local function slideFrame(frame, endPos, duration)
	if not frame then return end
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(frame, tweenInfo, {Position = endPos})
	tween:Play()
	tween.Completed:Wait()
end

-- Fade GUI Contents
local function fadeGuiContents(gui, endTransparency, duration)
	if not gui then return end
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, obj in ipairs(gui:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			TweenService:Create(obj, tweenInfo, {TextTransparency = endTransparency}):Play()
		elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			TweenService:Create(obj, tweenInfo, {ImageTransparency = endTransparency}):Play()
		elseif obj:IsA("Frame") then
			TweenService:Create(obj, tweenInfo, {BackgroundTransparency = endTransparency}):Play()
		end
	end
	task.wait(duration)
end

-- Start Quiz
function QuizManager:StartQuiz(data, quizIdParam)
	quizId = quizIdParam or "unknown"
	currentData = data.Quiz or {}
	currentQuestionIndex = 1
	score = 0
	answering = false

	if #currentData == 0 then
		warn("[quiz] Tidak ada pertanyaan di quizData!")
		return
	end

	local playerGui = getPlayerGui()
	if not playerGui then return end

	quizGui = playerGui:WaitForChild("visual")
	quizGui.Enabled = true

	fadeUI("in", function()
		self:DisplayQuestion(true)
	end)
end

-- Display Question
function QuizManager:DisplayQuestion(isFirst)
	if not currentData or currentQuestionIndex > #currentData then
		self:EndQuiz()
		return
	end

	local playerGui = getPlayerGui()
	if not playerGui then return end

	local backFrame = quizGui:FindFirstChild("refleksi")
	local mainFrame = backFrame and backFrame:FindFirstChild("main")
	local quizFrame = mainFrame and mainFrame:FindFirstChild("quizFrame")
	local imageQuiz = mainFrame and mainFrame:FindFirstChild("imageFrame")

	if not quizFrame or not imageQuiz then return end

	answering = false

	quizFrame.A.Visible = true
	quizFrame.B.Visible = true

	if not isFirst then
		slideFrame(mainFrame, UDim2.new(mainFrame.Position.X.Scale, 0, 2.2, 0), 0.4)
	end

	local questionData = currentData[currentQuestionIndex] or {}
	quizFrame.quizText.Text = questionData.Question or "Tidak ada pertanyaan"
	quizFrame.quizHint.Text = questionData.Hint or ""
	imageQuiz.image.Image = questionData.image or ""

	quizFrame.A.Text = (questionData.Options and questionData.Options.A) or "Opsi A kosong"
	quizFrame.B.Text = (questionData.Options and questionData.Options.B) or "Opsi B kosong"

	if not isFirst then
		slideFrame(mainFrame, UDim2.new(mainFrame.Position.X.Scale, 0, 0.5, 0), 0.4)
	end
end

-- Select Answer
function QuizManager:SelectAnswer(option)
	if answering then return end
	answering = true

	local playerGui = getPlayerGui()
	if not playerGui then return end

	local mainFrame = quizGui.refleksi.main
	local quizFrame = mainFrame.quizFrame
	local quizText = quizFrame.quizText

	local questionData = currentData[currentQuestionIndex] or {}
	local correctOption = questionData.CorrectOption

	if correctOption and option == correctOption then
		score += 1
		quizText.Text = "✅"
		local sfx = quizFrame:FindFirstChild("Right")
		if sfx then sfx:Play() end
	else
		quizText.Text = "❌"
		local sfx = quizFrame:FindFirstChild("Wrong")
		if sfx then sfx:Play() end
	end

	task.wait(0.5)
	currentQuestionIndex += 1
	self:DisplayQuestion()
end

-- End Quiz
function QuizManager:EndQuiz()
	local playerGui = getPlayerGui()
	if not playerGui then return end

	local quizFrame = quizGui.refleksi.main.quizFrame
	local quizText = quizFrame.quizText
	local totalQuestions = #currentData

	quizFrame.A.Visible = false
	quizFrame.B.Visible = false

	quizText.Text = string.format("Skor %d/%d", score, totalQuestions)
	task.wait(2)

	if score == totalQuestions then
		fadeUI("out", function()
			quizGui.Enabled = false
			local nextScene = currentData[#currentData].NextScene
			if nextScene then
				-- Fire event ke server bahwa quiz selesai
				game_event:FireServer("quiz_finished", {
					quiz_id = quizId,
					success = true,
					score = score,
					total_questions = totalQuestions,
				})

				local DialogManager = require(
					ReplicatedStorage.DialogGame.Handler:WaitForChild("DialogManager")
				)
				DialogManager:StartDialog(nextScene, "Chapter1")
			end
		end)
	else
		-- Quiz gagal, ulangi
		currentQuestionIndex = 1
		score = 0
		answering = false
		self:DisplayQuestion(false)
	end
end

-- Bind Buttons
function QuizManager:BindButtons()
	local playerGui = getPlayerGui()
	if not playerGui then return end

	local quizGui = playerGui:FindFirstChild("visual")
	if not quizGui then return end

	local quizFrame = quizGui.refleksi.main.quizFrame
	if not quizFrame then return end

	local A = quizFrame:FindFirstChild("A")
	local B = quizFrame:FindFirstChild("B")

	if A then
		A.MouseButton1Click:Connect(function()
			self:SelectAnswer("A")
		end)
	end
	if B then
		B.MouseButton1Click:Connect(function()
			self:SelectAnswer("B")
		end)
	end
end

-- Listen for quiz start event from server
game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name == "quiz_play" then
		local quizData = payload
		-- Extract quiz ID dari data atau gunakan default
		local paramQuizId = quizData.quiz_id or "quiz_1"
		QuizManager:StartQuiz(quizData, paramQuizId)
	end
end)

-- Bind buttons sekali saja saat script load
QuizManager:BindButtons()

return QuizManager