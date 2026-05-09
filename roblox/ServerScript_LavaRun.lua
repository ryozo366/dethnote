--!strict
-- Place in: ServerScriptService
-- Requires Workspace parts named: Start, Ziel, Lava
-- Enable HTTP/Studio API access? Not needed. Enable "Allow API Services" in Game Settings -> Security for DataStore.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Workspace        = game:GetService("Workspace")

----------------------------------------------------------------
-- Config
----------------------------------------------------------------
local LAVA_SPEED   = 5.5      -- studs per second
local LAVA_START_Y = -45.984
local LAVA_STOP_Y  = 180
local LAVA_START_POS = Vector3.new(13.676, LAVA_START_Y, 62.35)
local TOP_LIMIT    = 100

----------------------------------------------------------------
-- Parts
----------------------------------------------------------------
local startPart = Workspace:WaitForChild("Start")
local zielPart  = Workspace:WaitForChild("Ziel")
local lavaPart  = Workspace:WaitForChild("Lava")

lavaPart.Anchored      = true
lavaPart.CanCollide    = false
lavaPart.Material      = Enum.Material.CrackedLava
lavaPart.Color         = Color3.fromRGB(255, 80, 0)
lavaPart.Position      = LAVA_START_POS

----------------------------------------------------------------
-- Remotes
----------------------------------------------------------------
local remotes = ReplicatedStorage:FindFirstChild("LavaRunRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "LavaRunRemotes"
	remotes.Parent = ReplicatedStorage
end

local function makeRemote(name: string, class: string): Instance
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = remotes
	end
	return r
end

local TimerStart   = makeRemote("TimerStart",   "RemoteEvent") :: RemoteEvent
local TimerStop    = makeRemote("TimerStop",    "RemoteEvent") :: RemoteEvent
local TimerReset   = makeRemote("TimerReset",   "RemoteEvent") :: RemoteEvent
local Finished     = makeRemote("Finished",     "RemoteEvent") :: RemoteEvent
local LeaderUpdate = makeRemote("LeaderUpdate", "RemoteEvent") :: RemoteEvent
local GetLeader    = makeRemote("GetLeader",    "RemoteFunction") :: RemoteFunction

----------------------------------------------------------------
-- DataStore: Top times
----------------------------------------------------------------
local store = DataStoreService:GetOrderedDataStore("LavaRunTopTimes_v1")
local nameStore = DataStoreService:GetDataStore("LavaRunNames_v1")

-- Ordered store stores numbers; lower time = better. We store as integer
-- (ms) and sort ascending by negating into a "score" so GetSortedAsync
-- descending shows best first. Easier: store ms and read ascending.

local function loadTop(): {{name: string, ms: number}}
	local result = {}
	local ok, pages = pcall(function()
		return store:GetSortedAsync(true, TOP_LIMIT) -- ascending = lowest first
	end)
	if not ok or not pages then return result end
	local page = pages:GetCurrentPage()
	for _, entry in ipairs(page) do
		local userId = tostring(entry.key)
		local ms = entry.value
		local nm = "Player"
		local ok2, val = pcall(function() return nameStore:GetAsync(userId) end)
		if ok2 and typeof(val) == "string" then nm = val end
		table.insert(result, { name = nm, ms = ms })
	end
	return result
end

local function broadcastLeader()
	local top = loadTop()
	LeaderUpdate:FireAllClients(top)
end

GetLeader.OnServerInvoke = function(_player)
	return loadTop()
end

local function submitTime(player: Player, ms: number)
	local key = tostring(player.UserId)
	pcall(function() nameStore:SetAsync(key, player.Name) end)
	-- Only overwrite if better (lower) than existing
	local ok, prev = pcall(function() return store:GetAsync(key) end)
	if ok and typeof(prev) == "number" and prev <= ms then return end
	pcall(function() store:SetAsync(key, ms) end)
	broadcastLeader()
end

----------------------------------------------------------------
-- Run state per player
----------------------------------------------------------------
type RunState = {
	active: boolean,
	startTime: number,
	died: boolean,
}

local runs: {[Player]: RunState} = {}

local function getOrCreateRun(p: Player): RunState
	local r = runs[p]
	if not r then
		r = { active = false, startTime = 0, died = false }
		runs[p] = r
	end
	return r
end

local function teleportToStart(player: Player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = startPart.CFrame + Vector3.new(0, 5, 0)
	end
end

----------------------------------------------------------------
-- Lava logic
----------------------------------------------------------------
local lavaActive = false
local lavaY = LAVA_START_Y

local function resetLava()
	lavaActive = false
	lavaY = LAVA_START_Y
	lavaPart.Position = Vector3.new(LAVA_START_POS.X, LAVA_START_Y, LAVA_START_POS.Z)
end

local function anyRunActive(): boolean
	for _, r in pairs(runs) do
		if r.active then return true end
	end
	return false
end

RunService.Heartbeat:Connect(function(dt)
	if not lavaActive then return end
	if lavaY < LAVA_STOP_Y then
		lavaY = math.min(LAVA_STOP_Y, lavaY + LAVA_SPEED * dt)
		lavaPart.Position = Vector3.new(LAVA_START_POS.X, lavaY, LAVA_START_POS.Z)
	end
	if not anyRunActive() then
		resetLava()
	end
end)

----------------------------------------------------------------
-- Lava kills players
----------------------------------------------------------------
lavaPart.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local player = Players:GetPlayerFromCharacter(char)
	if humanoid and player then
		humanoid.Health = 0
	end
end)

----------------------------------------------------------------
-- Touch handlers
----------------------------------------------------------------
local touchDebounce: {[Player]: number} = {}

local function debounced(player: Player, key: string): boolean
	local now = tick()
	local k = key .. tostring(player.UserId)
	if touchDebounce[k :: any] and now - touchDebounce[k :: any] < 0.5 then return false end
	touchDebounce[k :: any] = now
	return true
end

startPart.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	if not char then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	if not debounced(player, "start") then return end

	local r = getOrCreateRun(player)
	if r.active then return end
	r.active = true
	r.died = false
	r.startTime = tick()

	lavaActive = true
	TimerStart:FireClient(player)
end)

zielPart.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	if not char then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	if not debounced(player, "ziel") then return end

	local r = getOrCreateRun(player)
	if not r.active or r.died then return end

	local elapsed = tick() - r.startTime
	local ms = math.floor(elapsed * 1000)
	r.active = false

	TimerStop:FireClient(player, ms)
	Finished:FireClient(player, ms)
	submitTime(player, ms)
end)

----------------------------------------------------------------
-- Death handling
----------------------------------------------------------------
local function bindCharacter(player: Player, char: Model)
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		local r = getOrCreateRun(player)
		if r.active then
			r.active = false
			r.died = true
			TimerReset:FireClient(player)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	getOrCreateRun(player)
	if player.Character then bindCharacter(player, player.Character) end
	player.CharacterAdded:Connect(function(c) bindCharacter(player, c) end)
	-- send current leaderboard
	task.delay(2, function()
		local top = loadTop()
		LeaderUpdate:FireClient(player, top)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	runs[player] = nil
end)

-- initial broadcast
task.spawn(broadcastLeader)
