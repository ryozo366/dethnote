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
-- Remotes (created FIRST so the LocalScript can find them
-- even if something below errors)
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
-- Parts (accepts either "Finish" or legacy "Ziel")
----------------------------------------------------------------
local function trim(s: string): string
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function findPart(name: string, fallback: string?): Instance
	-- 1. exact match
	local p = Workspace:FindFirstChild(name)
	if not p and fallback then p = Workspace:FindFirstChild(fallback) end
	-- 2. tolerant: trim + case-insensitive comparison against every child
	if not p then
		local target  = name:lower()
		local target2 = fallback and fallback:lower() or nil
		for _, child in ipairs(Workspace:GetChildren()) do
			local n = trim(child.Name):lower()
			if n == target or (target2 and n == target2) then
				p = child
				warn(("[LavaRun] Matched '%s' loosely to Workspace.%s"):format(name, child.Name))
				break
			end
		end
	end
	-- 3. last resort: yield briefly
	if not p then
		warn(("[LavaRun] Workspace.%s not found, waiting..."):format(name))
		p = Workspace:WaitForChild(name, 5)
		if not p and fallback then p = Workspace:WaitForChild(fallback, 5) end
	end
	assert(p, "[LavaRun] Could not find Workspace." .. name .. " (or " .. tostring(fallback) .. ")")
	return p
end

local startObject  = findPart("Start")
local finishObject = findPart("Finish", "Ziel")
local lavaObject   = findPart("Lava")

print("[LavaRun] Start =", startObject:GetFullName(), "ClassName:", startObject.ClassName)
print("[LavaRun] Finish =", finishObject:GetFullName(), "ClassName:", finishObject.ClassName)
print("[LavaRun] Lava =", lavaObject:GetFullName(), "ClassName:", lavaObject.ClassName)

local function collectBaseParts(inst: Instance): {BasePart}
	local out: {BasePart} = {}
	if inst:IsA("BasePart") then table.insert(out, inst) end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(out, d) end
	end
	return out
end

local startParts  = collectBaseParts(startObject)
local finishParts = collectBaseParts(finishObject)
print("[LavaRun] Start has", #startParts, "BaseParts; Finish has", #finishParts)
for _, p in ipairs(startParts)  do p.CanTouch = true end
for _, p in ipairs(finishParts) do p.CanTouch = true end

----------------------------------------------------------------
-- Lava template (the original is the template that gets cloned per player)
----------------------------------------------------------------
local FACES = {
	Enum.NormalId.Top, Enum.NormalId.Bottom,
	Enum.NormalId.Front, Enum.NormalId.Back,
	Enum.NormalId.Left, Enum.NormalId.Right,
}

local function applyDecals(part: BasePart)
	if LAVA_IMAGE_ID == "rbxassetid://0" then return end
	for _, face in ipairs(FACES) do
		local existing = part:FindFirstChild("LavaDecal_" .. face.Name)
		if existing then existing:Destroy() end
		pcall(function()
			local decal = Instance.new("Decal")
			decal.Name    = "LavaDecal_" .. face.Name
			decal.Texture = LAVA_IMAGE_ID
			decal.Face    = face
			decal.Parent  = part
		end)
	end
end

-- Hide the original (it serves only as the template / shape source)
local templateParts: {BasePart} = {}
do
	local function collect(inst: Instance)
		if inst:IsA("BasePart") then table.insert(templateParts, inst) end
		for _, child in ipairs(inst:GetChildren()) do collect(child) end
	end
	collect(lavaObject)
end
assert(#templateParts > 0, "Workspace.Lava must be a BasePart or contain BaseParts")
for _, p in ipairs(templateParts) do
	pcall(function() p.Anchored   = true end)
	pcall(function() p.CanCollide = false end)
	pcall(function() p.CanTouch   = false end)
	pcall(function() p.Transparency = 1 end)
end

-- Folder to hold all per-player lava clones
local lavaFolder = Workspace:FindFirstChild("LavaClones")
if not lavaFolder then
	lavaFolder = Instance.new("Folder")
	lavaFolder.Name = "LavaClones"
	lavaFolder.Parent = Workspace
end

----------------------------------------------------------------
-- Per-player lava state
----------------------------------------------------------------
type PlayerLava = {
	root: Instance,        -- the cloned Part or Model
	parts: {BasePart},
	y: number,
	active: boolean,
}

local lavas: {[Player]: PlayerLava} = {}

local function setLavaPivot(root: Instance, cf: CFrame)
	if root:IsA("BasePart") then
		(root :: BasePart).CFrame = cf
	elseif root:IsA("Model") then
		(root :: Model):PivotTo(cf)
	end
end

local function placeLavaY(state: PlayerLava, y: number)
	state.y = y
	setLavaPivot(state.root, CFrame.new(LAVA_START_POS.X, y, LAVA_START_POS.Z))
end

local function resetLavaFor(player: Player)
	local s = lavas[player]
	if not s then return end
	s.active = false
	placeLavaY(s, LAVA_START_Y)
end

local function createLavaFor(player: Player)
	if lavas[player] then return end

	-- Clone, then re-enable visibility/collision-free settings on the clone
	local clone = lavaObject:Clone()
	clone.Name = "Lava_" .. tostring(player.UserId)
	clone:SetAttribute("OwnerUserId", player.UserId)
	clone.Parent = lavaFolder

	local parts: {BasePart} = {}
	local function collect(inst: Instance)
		if inst:IsA("BasePart") then table.insert(parts, inst) end
		for _, child in ipairs(inst:GetChildren()) do collect(child) end
	end
	collect(clone)

	for _, p in ipairs(parts) do
		p:SetAttribute("OwnerUserId", player.UserId)
		pcall(function() p.Anchored     = true end)
		pcall(function() p.CanCollide   = false end)
		pcall(function() p.CanTouch     = true end)
		pcall(function() p.Transparency = 0 end)
		applyDecals(p)
	end

	local state: PlayerLava = {
		root   = clone,
		parts  = parts,
		y      = LAVA_START_Y,
		active = false,
	}
	lavas[player] = state
	placeLavaY(state, LAVA_START_Y)

	-- Touch only kills the owning player
	for _, p in ipairs(parts) do
		p.Touched:Connect(function(hit)
			local char = hit:FindFirstAncestorOfClass("Model")
			if not char then return end
			local hitPlayer = Players:GetPlayerFromCharacter(char)
			if hitPlayer ~= player then return end
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
	end
end

local function destroyLavaFor(player: Player)
	local s = lavas[player]
	if not s then return end
	pcall(function() s.root:Destroy() end)
	lavas[player] = nil
end

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
-- Lava heartbeat (per player)
----------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	for player, s in pairs(lavas) do
		local r = runs[player]
		if r and r.active then
			if s.y < LAVA_STOP_Y then
				placeLavaY(s, math.min(LAVA_STOP_Y, s.y + LAVA_SPEED * dt))
			end
		else
			if s.y > LAVA_START_Y then
				placeLavaY(s, LAVA_START_Y)
			end
		end
	end
end)

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
-- End run on death / leave
----------------------------------------------------------------
local function endRunDeath(player: Player)
	local r = runs[player]
	if not r or not r.active then return end
	r.active = false
	r.died   = true
	TimerReset:FireClient(player)
	resetLavaFor(player)
end

----------------------------------------------------------------
-- Touch handlers
----------------------------------------------------------------
local function onStartTouched(hit: BasePart)
	print("[LavaRun] Start touched by", hit:GetFullName())
	local char = hit:FindFirstAncestorOfClass("Model")
	if not char then return end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	if not debounced(player, "start") then return end

	local r = getOrCreateRun(player)
	if r.active then return end

	-- Make sure this player has a lava clone, then reset only theirs
	createLavaFor(player)
	resetLavaFor(player)

	r.active    = true
	r.died      = false
	r.startTime = os.clock()
	print("[LavaRun] Run started for", player.Name)
	TimerStart:FireClient(player)
end
for _, p in ipairs(startParts) do
	p.Touched:Connect(onStartTouched)
end
print("[LavaRun] Start.Touched connected on", #startParts, "part(s)")

local function onFinishTouched(hit: BasePart)
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
	print("[LavaRun] Finish for", player.Name, "in", ms, "ms")

	TimerStop:FireClient(player, ms)
	Finished:FireClient(player, ms)
	submitTime(player, ms)

	resetLavaFor(player)
end
for _, p in ipairs(finishParts) do
	p.Touched:Connect(onFinishTouched)
end

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
	createLavaFor(player)
	if player.Character then bindCharacter(player, player.Character) end
	player.CharacterAdded:Connect(function(c)
		local r = getOrCreateRun(player)
		r.active = false
		r.died   = false
		TimerReset:FireClient(player)
		resetLavaFor(player)
		bindCharacter(player, c)
	end)
	task.delay(2, function()
		LeaderUpdate:FireClient(player, loadTop())
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	endRunDeath(player)
	destroyLavaFor(player)
	runs[player] = nil
end)

-- Pre-create lavas for any players already in (script reloaded mid-game)
for _, p in ipairs(Players:GetPlayers()) do
	createLavaFor(p)
end

task.spawn(broadcastLeader)
