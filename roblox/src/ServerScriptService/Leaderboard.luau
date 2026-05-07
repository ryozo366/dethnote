-- Leaderboard: tracks each player's current stage
-- Place this Script inside ServerScriptService

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local stage = Instance.new("IntValue")
	stage.Name  = "Stage"
	stage.Value = 0
	stage.Parent = stats
end)
