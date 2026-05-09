--!strict
-- Place in: ServerScriptService (as a Script)
-- Required Workspace parts: "Start", "Finish", "Lava"
-- Enable in Game Settings -> Security: "Enable Studio Access to API Services" (for DataStore)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local DataStoreService  = game:GetService("DataStoreService")
local Workspace         = game:GetService("Workspace")

----------------------------------------------------------------
-- Config
----------------------------------------------------------------
local LAVA_SPEED     = 5.5         -- studs per second
local LAVA_START_Y   = -45.984
local LAVA_STOP_Y    = 180
local LAVA_START_POS = Vector3.new(13.676, LAVA_START_Y, 62.35)
local TOP_LIMIT      = 100

-- Replace this asset ID with the image you uploaded to Roblox
-- (Create -> Decals -> upload the picture, then copy the asset id).
local LAVA_IMAGE_ID  = "rbxassetid://0"

----------------------------------------------------------------
-- Parts
----------------------------------------------------------------
local startPart  = Workspace:WaitForChild("Start")  :: BasePart
local finishPart = Workspace:WaitForChild("Finish") :: BasePart
local lavaObject = Workspace:WaitForChild("Lava")

----------------------------------------------------------------
-- Lava can be either a single BasePart or a Model. Handle both.
----------------------------------------------------------------
local lavaParts: {BasePart} = {}

local function collectParts(inst: Instance)
	if inst:IsA("BasePart") then
		table.insert(lavaParts, inst)
	end
	for _, child in ipairs(inst:GetChildren()) do
		collectParts(child)
	end
end
collectParts(lavaObject)

assert(#lavaParts > 0, "Workspace.Lava must be a BasePart or contain BaseParts")

local FACES = {
	Enum.NormalId.Top, Enum.NormalId.Bottom,
	Enum.NormalId.Front, Enum.NormalId.Back,
	Enum.NormalId.Left, Enum.NormalId.Right,
}
for _, p in ipairs(lavaParts) do
	p.Anchored   = true
	p.CanCollide = false
	for _, face in ipairs(FACES) do
		local existing = p:FindFirstChild("LavaDecal_" .. face.Name)
		if existing then existing:Destroy() end
		local decal = Instance.new("Decal")
		decal.Name    = "LavaDecal_" .. face.Name
		decal.Texture = LAVA_IMAGE_ID
		decal.Face    = face
		decal.Parent  = p
	end
end

-- Compute initial pivot/position in a way that supports both Part and Model.
local function getLavaPivot(): CFrame
	if lavaObject:IsA("BasePart") then
		return lavaObject.CFrame
	elseif lavaObject:IsA("Model") then
		return lavaObject:GetPivot()
	end
	return CFrame.new(LAVA_START_POS)
end

local function setLavaPivot(cf: CFrame)
	if lavaObject:IsA("BasePart") then
		(lavaObject :: BasePart).CFrame = cf
	elseif lavaObject:IsA("Model") then
		(lavaObject :: Model):PivotTo(cf)
	end
end

setLavaPivot(CFrame.new(LAVA_START_POS))

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

local TimerStart   = makeRemote("TimerStart",   "RemoteEvent")    :: RemoteEvent
local TimerStop    = makeRemote("TimerStop",    "RemoteEvent")    :: RemoteEvent
local TimerReset   = makeRemote("TimerReset",   "RemoteEvent")    :: RemoteEvent
local Finished     = makeRemote("Finished",     "RemoteEvent")    :: RemoteEvent
local LeaderUpdate = makeRemote("LeaderUpdate", "RemoteEvent")    :: RemoteEvent
local GetLeader    = makeRemote("GetLeader",    "RemoteFunction") :: RemoteFunction

----------------------------------------------------------------
-- DataStore: Top times
----------------------------------------------------------------
local store     = DataStoreService:GetOrderedDataStore("LavaRunTopTimes_v1")
local nameStore = DataStoreService:GetDataStore("LavaRunNames_v1")

local function loadTop(): {{name: string, ms: number}}
	local result = {}
	local ok, pages = pcall(function()
		return store:GetSortedAsync(true, TOP_LIMIT) -- ascending: lowest time first
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
	LeaderUpdate:FireAllClients(loadTop())
end

GetLeader.OnServerInvoke = function(_player)
	return loadTop()
end

local function submitTime(player: Player, ms: number)
	local key = tostring(player.UserId)
	pcall(function() nameStore:SetAsync(key, player.Name) end)
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

----------------------------------------------------------------
-- Lava logic
----------------------------------------------------------------
local lavaActive = false
local lavaY = LAVA_START_Y

local function placeLava(y: number)
	lavaY = y
	setLavaPivot(CFrame.new(LAVA_START_POS.X, y, LAVA_START_POS.Z))
end

local function resetLava()
	lavaActive = false
	placeLava(LAVA_START_Y)
end

local function anyRunActive(): boolean
	for _, r in pairs(runs) do
		if r.active then return true end
	end
	return false
end

RunService.Heartbeat:Connect(function(dt)
	if not lavaActive then return end
	if not anyRunActive() then
		resetLava()
		return
	end
	if lavaY < LAVA_STOP_Y then
		placeLava(math.min(LAVA_STOP_Y, lavaY + LAVA_SPEED * dt))
	end
end)

----------------------------------------------------------------
-- Lava kills players (connect to every constituent part)
----------------------------------------------------------------
local function onLavaTouched(hit: BasePart)
	local char = hit:FindFirstAncestorOfClass("Model")
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local player = Players:GetPlayerFromCharacter(char)
	if humanoid and player and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end
for _, p in ipairs(lavaParts) do
	p.Touched:Connect(onLavaTouched)
end

----------------------------------------------------------------
-- Touch debounce
----------------------------------------------------------------
local touchDebounce: {[string]: number} = {}
local function debounced(player: Player, key: string): boolean
	local k = key .. "_" .. tostring(player.UserId)
	local now = os.clock()
	if touchDebounce[k] and now - touchDebounce[k] < 0.5 then return false end
	touchDebounce[k] = now
	return true
end

----------------------------------------------------------------
-- End run helper (called on death OR when leaving)
----------------------------------------------------------------
local function endRunDeath(player: Player)
	local r = runs[player]
	if not r or not r.active then return end
	r.active = false
	r.died   = true
	TimerReset:FireClient(player)
	-- if no other player is running, reset lava immediately
	if not anyRunActive() then
		resetLava()
	end
end

----------------------------------------------------------------
-- Touch handlers
----------------------------------------------------------------
startPart.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	if not char then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	if not debounced(player, "start") then return end

	local r = getOrCreateRun(player)
	if r.active then return end

	-- Always reset lava when a fresh run starts (handles post-death restart)
	resetLava()

	r.active    = true
	r.died      = false
	r.startTime = os.clock()

	lavaActive = true
	TimerStart:FireClient(player)
end)

finishPart.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	if not char then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	if not debounced(player, "finish") then return end

	local r = runs[player]
	if not r or not r.active or r.died then return end

	local elapsed = os.clock() - r.startTime
	local ms = math.floor(elapsed * 1000)
	r.active = false

	TimerStop:FireClient(player, ms)
	Finished:FireClient(player, ms)
	submitTime(player, ms)

	if not anyRunActive() then
		resetLava()
	end
end)

----------------------------------------------------------------
-- Death handling
----------------------------------------------------------------
local function bindCharacter(player: Player, char: Model)
	local humanoid = char:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		endRunDeath(player)
	end)
	-- Safety: if the character is removed for any reason during a run, end it.
	char.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			endRunDeath(player)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	getOrCreateRun(player)
	if player.Character then bindCharacter(player, player.Character) end
	player.CharacterAdded:Connect(function(c)
		-- New character spawn = always make sure their timer is cleared
		local r = getOrCreateRun(player)
		r.active = false
		r.died   = false
		TimerReset:FireClient(player)
		bindCharacter(player, c)
	end)
	task.delay(2, function()
		LeaderUpdate:FireClient(player, loadTop())
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	endRunDeath(player)
	runs[player] = nil
end)

task.spawn(broadcastLeader)
