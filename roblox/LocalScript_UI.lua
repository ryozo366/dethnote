-- Place in: StarterPlayer -> StarterPlayerScripts
-- Builds Timer + Top-Times leaderboard UI in pastel pink.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("LavaRunRemotes")
local TimerStart   = remotes:WaitForChild("TimerStart")
local TimerStop    = remotes:WaitForChild("TimerStop")
local TimerReset   = remotes:WaitForChild("TimerReset")
local LeaderUpdate = remotes:WaitForChild("LeaderUpdate")
local GetLeader    = remotes:WaitForChild("GetLeader")

----------------------------------------------------------------
-- Pastel pink palette
----------------------------------------------------------------
local PINK_BG     = Color3.fromRGB(255, 228, 235) -- soft pastel pink
local PINK_PANEL  = Color3.fromRGB(255, 209, 220)
local PINK_DARK   = Color3.fromRGB(232, 145, 170)
local PINK_TEXT   = Color3.fromRGB(120, 60, 90)
local GOLD        = Color3.fromRGB(212, 175, 55)
local SILVER      = Color3.fromRGB(192, 192, 192)
local BRONZE      = Color3.fromRGB(205, 127, 50)
local WHITE       = Color3.fromRGB(255, 255, 255)

----------------------------------------------------------------
-- ScreenGui
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "LavaRunUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or PINK_DARK
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function gradient(parent, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

local function formatMs(ms: number): string
	local totalSec = ms / 1000
	local minutes = math.floor(totalSec / 60)
	local seconds = math.floor(totalSec % 60)
	local millis  = ms % 1000
	return string.format("%02d:%02d.%03d", minutes, seconds, millis)
end

----------------------------------------------------------------
-- Timer panel
----------------------------------------------------------------
local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.AnchorPoint = Vector2.new(0.5, 0)
timerFrame.Position = UDim2.new(0.5, 0, 0, 16)
timerFrame.Size = UDim2.fromOffset(260, 70)
timerFrame.BackgroundColor3 = PINK_PANEL
timerFrame.BorderSizePixel = 0
timerFrame.Parent = gui
corner(timerFrame, 16)
stroke(timerFrame, PINK_DARK, 2)
gradient(timerFrame, PINK_BG, PINK_PANEL, 90)

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Time"
timerLabel.BackgroundTransparency = 1
timerLabel.Size = UDim2.fromScale(1, 0.6)
timerLabel.Position = UDim2.fromScale(0, 0.3)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextScaled = true
timerLabel.TextColor3 = PINK_TEXT
timerLabel.Text = "00:00.000"
timerLabel.Parent = timerFrame

local timerTitle = Instance.new("TextLabel")
timerTitle.BackgroundTransparency = 1
timerTitle.Size = UDim2.new(1, 0, 0, 20)
timerTitle.Position = UDim2.new(0, 0, 0, 6)
timerTitle.Font = Enum.Font.Gotham
timerTitle.TextScaled = true
timerTitle.TextColor3 = PINK_DARK
timerTitle.Text = "RUN TIME"
timerTitle.Parent = timerFrame

----------------------------------------------------------------
-- Timer logic
----------------------------------------------------------------
local timerRunning = false
local timerStartTick = 0
local timerConn: RBXScriptConnection? = nil

local function stopTimer()
	timerRunning = false
	if timerConn then timerConn:Disconnect() timerConn = nil end
end

local function startTimer()
	stopTimer()
	timerRunning = true
	timerStartTick = tick()
	timerLabel.TextColor3 = PINK_TEXT
	timerConn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - timerStartTick
		local ms = math.floor(elapsed * 1000)
		timerLabel.Text = formatMs(ms)
	end)
end

TimerStart.OnClientEvent:Connect(function()
	startTimer()
end)

TimerStop.OnClientEvent:Connect(function(ms)
	stopTimer()
	timerLabel.Text = formatMs(ms)
	timerLabel.TextColor3 = Color3.fromRGB(60, 140, 80)
end)

TimerReset.OnClientEvent:Connect(function()
	stopTimer()
	timerLabel.Text = "00:00.000"
	timerLabel.TextColor3 = Color3.fromRGB(180, 60, 80)
end)

-- Client-side safety: if our character dies, stop the local timer immediately
local function bindCharacter(char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		stopTimer()
		timerLabel.Text = "00:00.000"
		timerLabel.TextColor3 = Color3.fromRGB(180, 60, 80)
	end)
end
if player.Character then bindCharacter(player.Character) end
player.CharacterAdded:Connect(bindCharacter)

----------------------------------------------------------------
-- Leaderboard panel
----------------------------------------------------------------
local board = Instance.new("Frame")
board.Name = "TopTimes"
board.AnchorPoint = Vector2.new(1, 0.5)
board.Position = UDim2.new(1, -20, 0.5, 0)
board.Size = UDim2.fromOffset(320, 520)
board.BackgroundColor3 = PINK_BG
board.BorderSizePixel = 0
board.Parent = gui
corner(board, 18)
stroke(board, PINK_DARK, 2)
gradient(board, PINK_BG, PINK_PANEL, 135)

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 56)
header.BackgroundColor3 = PINK_PANEL
header.BorderSizePixel = 0
header.Parent = board
corner(header, 18)
gradient(header, PINK_PANEL, PINK_DARK, 90)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 18)
headerFix.Position = UDim2.new(0, 0, 1, -18)
headerFix.BackgroundColor3 = PINK_PANEL
headerFix.BorderSizePixel = 0
headerFix.Parent = header
gradient(headerFix, PINK_PANEL, PINK_DARK, 90)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = WHITE
title.Text = "TOP 100 TIMES"
title.Name = "Title"
title.Parent = header
stroke(title, PINK_TEXT, 1)

-- Scrolling list
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "List"
scroll.Size = UDim2.new(1, -16, 1, -72)
scroll.Position = UDim2.new(0, 8, 0, 64)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = PINK_DARK
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = board

local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 4)
list.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 4)
pad.Parent = scroll

local function rankColor(rank: number): Color3
	if rank == 1 then return GOLD end
	if rank == 2 then return SILVER end
	if rank == 3 then return BRONZE end
	return PINK_PANEL
end

local function makeRow(rank: number, name: string, ms: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 36)
	row.BackgroundColor3 = (rank % 2 == 0) and PINK_BG or WHITE
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel = 0
	row.LayoutOrder = rank
	row.Parent = scroll
	corner(row, 8)

	local rankBadge = Instance.new("Frame")
	rankBadge.Size = UDim2.fromOffset(36, 28)
	rankBadge.Position = UDim2.new(0, 4, 0.5, -14)
	rankBadge.BackgroundColor3 = rankColor(rank)
	rankBadge.BorderSizePixel = 0
	rankBadge.Parent = row
	corner(rankBadge, 6)

	local rankText = Instance.new("TextLabel")
	rankText.BackgroundTransparency = 1
	rankText.Size = UDim2.fromScale(1, 1)
	rankText.Font = Enum.Font.GothamBold
	rankText.TextScaled = true
	rankText.TextColor3 = (rank <= 3) and WHITE or PINK_TEXT
	rankText.Text = "#" .. rank
	rankText.Parent = rankBadge

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 48, 0, 0)
	nameLabel.Size = UDim2.new(0.55, -52, 1, 0)
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = PINK_TEXT
	nameLabel.Text = name
	nameLabel.Parent = row

	local timeLabel = Instance.new("TextLabel")
	timeLabel.BackgroundTransparency = 1
	timeLabel.Position = UDim2.new(0.55, 0, 0, 0)
	timeLabel.Size = UDim2.new(0.45, -8, 1, 0)
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextScaled = true
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeLabel.TextColor3 = PINK_DARK
	timeLabel.Text = formatMs(ms)
	timeLabel.Parent = row
end

local function renderTop(top)
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	if not top or #top == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.Font = Enum.Font.Gotham
		empty.TextScaled = true
		empty.TextColor3 = PINK_DARK
		empty.Text = "No times yet - be the first!"
		empty.Parent = scroll
		return
	end
	for i, entry in ipairs(top) do
		makeRow(i, entry.name, entry.ms)
	end
end

LeaderUpdate.OnClientEvent:Connect(renderTop)

-- initial fetch
task.spawn(function()
	local ok, top = pcall(function() return GetLeader:InvokeServer() end)
	if ok then renderTop(top) end
end)
