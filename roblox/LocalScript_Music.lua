-- Place in: StarterPlayer -> StarterPlayerScripts (as a LocalScript)
-- Background music with playlist + mute toggle (M key, also a UI button).

local Players      = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local UserInput    = game:GetService("UserInputService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- Playlist: replace these IDs with your own audio assets
-- (Creator Hub -> Audio -> upload, or Toolbox -> copy ID)
----------------------------------------------------------------
local PLAYLIST = {
	"rbxassetid://9046862147", -- placeholder lofi 1
	"rbxassetid://1837849217", -- placeholder lofi 2
	"rbxassetid://1839997588", -- placeholder synthwave
}
local VOLUME = 0.4

----------------------------------------------------------------
-- Sound object
----------------------------------------------------------------
local sound = Instance.new("Sound")
sound.Name = "BGM"
sound.Volume = VOLUME
sound.Looped = false
sound.Parent = SoundService

local idx = 0
local muted = false

local function playNext()
	if muted then return end
	if #PLAYLIST == 0 then return end
	idx = (idx % #PLAYLIST) + 1
	sound.SoundId = PLAYLIST[idx]
	sound.TimePosition = 0
	sound:Play()
end

sound.Ended:Connect(playNext)
sound:GetPropertyChangedSignal("IsLoaded"):Connect(function()
	if not sound.IsLoaded and sound.SoundId ~= "" then
		warn("[Music] couldn't load", sound.SoundId, "- skipping")
	end
end)

----------------------------------------------------------------
-- Mute UI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "MusicUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = pg

local btn = Instance.new("TextButton")
btn.AnchorPoint = Vector2.new(1, 1)
btn.Position = UDim2.new(1, -170, 1, -20)
btn.Size = UDim2.fromOffset(48, 48)
btn.BackgroundColor3 = Color3.fromRGB(232, 145, 170)
btn.BorderSizePixel = 0
btn.Font = Enum.Font.GothamBold
btn.TextScaled = true
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Text = "♪"
btn.Parent = gui
local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = btn
local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(255,255,255) s.Thickness = 2 s.Parent = btn

local function setMuted(v)
	muted = v
	if muted then
		sound:Pause()
		btn.Text = "X"
		btn.BackgroundColor3 = Color3.fromRGB(120, 60, 90)
	else
		btn.Text = "♪"
		btn.BackgroundColor3 = Color3.fromRGB(232, 145, 170)
		if sound.SoundId == "" then
			playNext()
		else
			sound:Resume()
		end
	end
end

btn.MouseButton1Click:Connect(function() setMuted(not muted) end)

UserInput.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.M then
		setMuted(not muted)
	end
end)

playNext()
