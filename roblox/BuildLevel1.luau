-- FemBoy Obby - Level 1 Build Script
-- Run this in Roblox Studio Command Bar (View > Command Bar) to generate the map.
-- Make sure to run it ONCE on an empty baseplate.

local workspace = game:GetService("Workspace")

-- Color palette
local PINK       = Color3.fromRGB(255, 182, 213)
local HOT_PINK   = Color3.fromRGB(255, 105, 180)
local LAVENDER   = Color3.fromRGB(200, 170, 255)
local SOFT_PURPLE= Color3.fromRGB(160, 100, 220)
local WHITE      = Color3.fromRGB(255, 255, 255)
local PASTEL_BLUE= Color3.fromRGB(180, 220, 255)
local GOLD       = Color3.fromRGB(255, 215, 100)

local mapFolder = Instance.new("Folder")
mapFolder.Name = "FemboyObby_Level1"
mapFolder.Parent = workspace

-- ── Helper functions ──────────────────────────────────────────────────────────

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored    = props.anchored ~= false
	p.Size        = props.size    or Vector3.new(6, 1, 6)
	p.Position    = props.pos     or Vector3.new(0, 0, 0)
	p.Color       = props.color   or PINK
	p.Material    = props.mat     or Enum.Material.SmoothPlastic
	p.TopSurface  = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow  = true
	if props.name then p.Name = props.name end
	if props.canCollide ~= nil then p.CanCollide = props.canCollide end
	p.Parent = mapFolder
	return p
end

local function makeWedge(props)
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.Size     = props.size  or Vector3.new(4, 1, 4)
	p.Position = props.pos   or Vector3.new(0, 0, 0)
	p.Color    = props.color or LAVENDER
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface  = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = mapFolder
	return p
end

-- Glitter / sparkle decal on a surface
local function addDecal(part, face, id)
	local d = Instance.new("Decal")
	d.Texture = id
	d.Face    = face
	d.Parent  = part
end

-- Neon sign text
local function makeSign(text, pos, color)
	local b = Instance.new("Part")
	b.Anchored = true
	b.Size     = Vector3.new(8, 2, 0.3)
	b.Position = pos
	b.Color    = Color3.fromRGB(20, 10, 30)
	b.Material = Enum.Material.SmoothPlastic
	b.TopSurface  = Enum.SurfaceType.Smooth
	b.BottomSurface = Enum.SurfaceType.Smooth
	b.Parent = mapFolder

	local sg = Instance.new("SurfaceGui")
	sg.Face   = Enum.NormalId.Front
	sg.Parent = b

	local label = Instance.new("TextLabel")
	label.Size            = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text            = text
	label.TextColor3      = color or HOT_PINK
	label.TextScaled      = true
	label.Font            = Enum.Font.GothamBold
	label.Parent          = sg
end

-- Spinning kill brick
local function makeSpinner(pos, color)
	local p = makePart({
		pos   = pos,
		size  = Vector3.new(14, 1, 1.5),
		color = color or HOT_PINK,
		mat   = Enum.Material.Neon,
	})
	p.Anchored = false
	p.Name     = "Spinner"

	local bp = Instance.new("BodyAngularVelocity")
	bp.AngularVelocity = Vector3.new(0, 2.5, 0)
	bp.MaxTorque       = Vector3.new(0, math.huge, 0)
	bp.Parent = p

	-- Kill on touch
	local kill = Instance.new("Script")
	kill.Source = [[
		script.Parent.Touched:Connect(function(hit)
			local h = hit.Parent:FindFirstChildWhichIsA("Humanoid")
			if h then h.Health = 0 end
		end)
	]]
	kill.Parent = p
	return p
end

-- Moving platform (weaves left/right via TweenService)
local function makeMovingPlatform(startPos, color, range, speed)
	local p = makePart({
		pos   = startPos,
		size  = Vector3.new(6, 1, 6),
		color = color or LAVENDER,
	})
	p.Name = "MovingPlatform"

	local script = Instance.new("Script")
	script.Source = string.format([[
		local TweenService = game:GetService("TweenService")
		local part = script.Parent
		local origin = part.Position
		local goal1  = {Position = origin + Vector3.new(%d, 0, 0)}
		local goal2  = {Position = origin - Vector3.new(%d, 0, 0)}
		local info   = TweenInfo.new(%g, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(part, info, goal1):Play()
	]], range, range, speed)
	script.Parent = p
	return p
end

-- Checkpoint flag
local function makeCheckpoint(pos, number)
	local pole = makePart({
		pos   = pos,
		size  = Vector3.new(0.5, 8, 0.5),
		color = WHITE,
		mat   = Enum.Material.Metal,
	})
	pole.Name = "CheckpointPole_" .. number

	local flag = makePart({
		pos   = Vector3.new(pos.X + 1.5, pos.Y + 3, pos.Z),
		size  = Vector3.new(3, 2, 0.2),
		color = HOT_PINK,
		mat   = Enum.Material.Neon,
	})
	flag.Name = "CheckpointFlag_" .. number

	-- Touch detection
	local s = Instance.new("Script")
	s.Source = string.format([[
		local num = %d
		script.Parent.Touched:Connect(function(hit)
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if not player then return end
			local data = player:FindFirstChild("leaderstats")
			if data then
				data.Stage.Value = math.max(data.Stage.Value, num)
			end
		end)
	]], number)
	s.Parent = flag
end

-- Cat Ear decoration (two wedges on top of a platform)
local function addCatEars(platform)
	local px = platform.Position.X
	local py = platform.Position.Y + platform.Size.Y / 2
	local pz = platform.Position.Z

	for _, side in ipairs({-1.5, 1.5}) do
		local ear = makeWedge({
			pos   = Vector3.new(px + side, py + 1.5, pz),
			size  = Vector3.new(1.5, 3, 1.5),
			color = HOT_PINK,
		})
		ear.Name = "CatEar"
	end
end

-- Heart shape (two cylinders + a rotated block)
local function makeHeart(pos, color)
	local c1 = makePart({pos = pos + Vector3.new(-0.7, 0, 0), size = Vector3.new(1.4, 1.4, 0.4), color = color or HOT_PINK, mat = Enum.Material.Neon})
	c1.Shape = Enum.PartType.Ball
	c1.Size  = Vector3.new(1.4, 1.4, 1.4)
	local c2 = makePart({pos = pos + Vector3.new(0.7, 0, 0), size = Vector3.new(1.4, 1.4, 0.4), color = color or HOT_PINK, mat = Enum.Material.Neon})
	c2.Shape = Enum.PartType.Ball
	c2.Size  = Vector3.new(1.4, 1.4, 1.4)
	local tip = makePart({pos = pos + Vector3.new(0, -1.1, 0), size = Vector3.new(1.4, 1.4, 1.4), color = color or HOT_PINK, mat = Enum.Material.Neon})
	tip.Shape = Enum.PartType.Ball
end

-- ── MAP LAYOUT ────────────────────────────────────────────────────────────────
-- Y = height, X = right, Z = forward (negative Z = forward in Roblox by default)
-- Each "section" is a named block below.

-- ── SECTION 0: Spawn Platform ────────────────────────────────────────────────
local spawnPad = makePart({
	name  = "SpawnPlatform",
	pos   = Vector3.new(0, 2, 0),
	size  = Vector3.new(16, 2, 16),
	color = PINK,
	mat   = Enum.Material.SmoothPlastic,
})
addCatEars(spawnPad)
makeSign("✧ FEMBOY OBBY ✧", Vector3.new(0, 6, -8.5), HOT_PINK)
makeSign("Stage 1 - Pastel Path", Vector3.new(0, 4, 8.5), LAVENDER)

-- Small heart decorations around spawn
makeHeart(Vector3.new(-7, 4.5, 0), HOT_PINK)
makeHeart(Vector3.new(7, 4.5, 0), LAVENDER)

-- ── SECTION 1: Pastel Stepping Stones ────────────────────────────────────────
local colors1 = {PINK, LAVENDER, PASTEL_BLUE, PINK, LAVENDER}
local stoneZ = -18
for i, c in ipairs(colors1) do
	local xOffset = (i % 2 == 0) and 5 or -5
	makePart({
		pos   = Vector3.new(xOffset, 3 + (i * 0.4), stoneZ - (i * 7)),
		size  = Vector3.new(5, 1, 5),
		color = c,
	})
end

makeCheckpoint(Vector3.new(0, 3.5, stoneZ - 46), 1)

-- ── SECTION 2: Moving Platforms over the Void ────────────────────────────────
local movZ = stoneZ - 55
makeSign("~ Float Like a Femboy ~", Vector3.new(0, 6, movZ - 5), LAVENDER)

makeMovingPlatform(Vector3.new(0,  4, movZ - 10),  LAVENDER,  8, 1.8)
makeMovingPlatform(Vector3.new(0,  4, movZ - 22),  HOT_PINK,  6, 1.4)
makeMovingPlatform(Vector3.new(0,  4, movZ - 34),  PASTEL_BLUE, 10, 2.0)
makeMovingPlatform(Vector3.new(0,  4, movZ - 46),  PINK,      7, 1.6)

makeCheckpoint(Vector3.new(0, 4, movZ - 56), 2)

-- Gap platform to land on after moving section
makePart({pos = Vector3.new(0, 4, movZ - 60), size = Vector3.new(10, 1, 6), color = PINK})

-- ── SECTION 3: Cat Ear Tower Climb ───────────────────────────────────────────
local towerX = 15
local towerBaseZ = movZ - 68
makeSign("Climb the Tower, Kitty!", Vector3.new(towerX, 6, towerBaseZ + 2), HOT_PINK)

local towerColors = {PINK, LAVENDER, HOT_PINK, PASTEL_BLUE, LAVENDER, PINK, HOT_PINK}
for i, c in ipairs(towerColors) do
	local side = (i % 2 == 0) and 1 or -1
	local platform = makePart({
		pos   = Vector3.new(towerX + side * 6, 4 + (i * 5), towerBaseZ - (i * 1.5)),
		size  = Vector3.new(5, 1, 5),
		color = c,
	})
	if i % 3 == 0 then addCatEars(platform) end
end

makeCheckpoint(Vector3.new(towerX, 4 + (#towerColors * 5) + 2, towerBaseZ - #towerColors * 1.5 - 3), 3)

-- ── SECTION 4: Spinner Gauntlet ───────────────────────────────────────────────
local spinZ = towerBaseZ - (#towerColors * 1.5) - 15
local spinY = 4 + (#towerColors * 5)
makeSign("!!! Danger Zone !!!", Vector3.new(0, spinY + 3, spinZ + 2), Color3.fromRGB(255, 80, 80))

-- Safe platforms between spinners
local spinPlatformPositions = {
	Vector3.new(0, spinY, spinZ),
	Vector3.new(0, spinY, spinZ - 14),
	Vector3.new(0, spinY, spinZ - 28),
	Vector3.new(0, spinY, spinZ - 42),
}
for _, pos in ipairs(spinPlatformPositions) do
	makePart({pos = pos, size = Vector3.new(5, 1, 4), color = WHITE})
end

makeSpinner(Vector3.new(0, spinY + 1, spinZ - 7),  HOT_PINK)
makeSpinner(Vector3.new(0, spinY + 1, spinZ - 21), SOFT_PURPLE)
makeSpinner(Vector3.new(0, spinY + 1, spinZ - 35), HOT_PINK)

makeCheckpoint(Vector3.new(0, spinY, spinZ - 50), 4)

-- ── SECTION 5: Rainbow Bridge (narrow) ───────────────────────────────────────
local bridgeZ = spinZ - 58
local bridgeY = spinY
makeSign("~ Walk the Rainbow Path ~", Vector3.new(0, bridgeY + 3, bridgeZ + 2), GOLD)

local rainbowColors = {
	Color3.fromRGB(255, 150, 180),
	Color3.fromRGB(255, 200, 130),
	Color3.fromRGB(200, 255, 160),
	Color3.fromRGB(160, 220, 255),
	Color3.fromRGB(200, 160, 255),
	Color3.fromRGB(255, 160, 200),
}
for i, c in ipairs(rainbowColors) do
	makePart({
		pos   = Vector3.new(0, bridgeY, bridgeZ - (i * 5)),
		size  = Vector3.new(3, 1, 5),
		color = c,
		mat   = Enum.Material.Neon,
	})
end

-- ── SECTION 6: Final Platform & Win ──────────────────────────────────────────
local endZ = bridgeZ - (#rainbowColors * 5) - 10
local endY = bridgeY

local endPad = makePart({
	name  = "WinPlatform",
	pos   = Vector3.new(0, endY, endZ),
	size  = Vector3.new(20, 2, 20),
	color = GOLD,
	mat   = Enum.Material.Neon,
})
addCatEars(endPad)
makeSign("✧ YOU WIN! ✧", Vector3.new(0, endY + 5, endZ), GOLD)
makeSign("Stage Clear ~  OwO  ~", Vector3.new(0, endY + 3, endZ + 10.5), HOT_PINK)

-- Hearts scattered on win platform
for _, offset in ipairs({-6, -2, 2, 6}) do
	makeHeart(Vector3.new(offset, endY + 3, endZ), HOT_PINK)
end

-- Win detection + fireworks effect
local winScript = Instance.new("Script")
winScript.Source = [[
	local part = script.Parent
	local debounce = {}

	part.Touched:Connect(function(hit)
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if not player or debounce[player.UserId] then return end
		debounce[player.UserId] = true

		-- Stage complete GUI
		local sg = Instance.new("ScreenGui", player.PlayerGui)
		sg.Name = "WinGui"
		local frame = Instance.new("Frame", sg)
		frame.Size = UDim2.new(0.4, 0, 0.2, 0)
		frame.Position = UDim2.new(0.3, 0, 0.4, 0)
		frame.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
		local label = Instance.new("TextLabel", frame)
		label.Size = UDim2.new(1,0,1,0)
		label.Text = "🎉 Stage Clear! UwU 🎉"
		label.TextScaled = true
		label.TextColor3 = Color3.new(1,1,1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold

		task.wait(4)
		sg:Destroy()
		debounce[player.UserId] = nil
	end)
]]
winScript.Parent = endPad

-- ── LEADERBOARD SETUP (goes in ServerScriptService, not here) ─────────────────
-- See src/ServerScriptService/Leaderboard.luau

-- ── Baseplate cleanup hint ────────────────────────────────────────────────────
print("✧ FemBoy Obby Level 1 built! ✧")
print("Tip: Delete the default Baseplate in Explorer > Workspace for a cleaner void look.")
print("Tip: Add a SpawnLocation inside the SpawnPlatform area (Model tab > Spawn).")
