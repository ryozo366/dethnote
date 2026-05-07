-- FemBoy Obby - Level 1 Build Script v2
-- Run in Roblox Studio Command Bar (View > Command Bar)
-- Paste EVERYTHING and press Enter once.

local workspace = game:GetService("Workspace")

-- Clean up old run
local old = workspace:FindFirstChild("FemboyObby_Level1")
if old then old:Destroy() end
local oldSL = workspace:FindFirstChild("FemboySpawn")
if oldSL then oldSL:Destroy() end

local map = Instance.new("Folder")
map.Name = "FemboyObby_Level1"
map.Parent = workspace

-- ── Palette ───────────────────────────────────────────────────────────────────
local PINK        = Color3.fromRGB(255, 182, 213)
local HOT_PINK    = Color3.fromRGB(255, 105, 180)
local LAVENDER    = Color3.fromRGB(200, 170, 255)
local SOFT_PURPLE = Color3.fromRGB(160, 100, 220)
local WHITE       = Color3.fromRGB(255, 255, 255)
local PASTEL_BLUE = Color3.fromRGB(180, 220, 255)
local GOLD        = Color3.fromRGB(255, 215, 100)
local SKIN        = Color3.fromRGB(255, 220, 185)
local MINT        = Color3.fromRGB(180, 255, 210)
local RED_WARN    = Color3.fromRGB(255, 60, 100)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function mk(props)
	local p
	if props.wedge then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if props.shape then p.Shape = props.shape end
	end
	p.Anchored       = true
	p.TopSurface     = Enum.SurfaceType.Smooth
	p.BottomSurface  = Enum.SurfaceType.Smooth
	p.CastShadow     = props.shadow ~= false
	p.Size           = props.size   or Vector3.new(6, 2, 6)
	p.Position       = props.pos    or Vector3.new(0, 0, 0)
	p.Color          = props.color  or PINK
	p.Material       = props.mat    or Enum.Material.SmoothPlastic
	p.Transparency   = props.tr     or 0
	if props.name then p.Name = props.name end
	if props.noCollide then p.CanCollide = false end
	p.Parent = map
	return p
end

local function sign(text, pos, textColor)
	local board = mk({pos=pos, size=Vector3.new(10,2.5,0.4), color=Color3.fromRGB(15,5,30)})
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.Parent = board
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = textColor or HOT_PINK
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = sg
	-- also show on front
	local sg2 = Instance.new("SurfaceGui")
	sg2.Face = Enum.NormalId.Front
	sg2.Parent = board
	local lbl2 = lbl:Clone()
	lbl2.Parent = sg2
end

local function catEars(platform)
	local px = platform.Position.X
	local py = platform.Position.Y + platform.Size.Y * 0.5
	local pz = platform.Position.Z
	for _, sx in ipairs({-2, 2}) do
		mk({wedge=true, pos=Vector3.new(px+sx, py+1.5, pz), size=Vector3.new(1.2,3,1.2), color=HOT_PINK, shadow=false})
	end
end

local function bow(pos, color)
	color = color or HOT_PINK
	mk({pos=pos,                        size=Vector3.new(0.5,0.5,0.5), color=color, mat=Enum.Material.Neon, shape=Enum.PartType.Ball})
	mk({pos=pos+Vector3.new(-1.1,0.1,0), size=Vector3.new(1.8,1,0.3),  color=color, mat=Enum.Material.Neon})
	mk({pos=pos+Vector3.new(1.1,0.1,0),  size=Vector3.new(1.8,1,0.3),  color=color, mat=Enum.Material.Neon})
end

local function heart(pos, color)
	color = color or HOT_PINK
	for _, o in ipairs({Vector3.new(-0.65,0.3,0), Vector3.new(0.65,0.3,0), Vector3.new(0,-0.55,0)}) do
		mk({pos=pos+o, size=Vector3.new(1.3,1.3,1.3), color=color, mat=Enum.Material.Neon, shape=Enum.PartType.Ball})
	end
end

-- Spinning laser (ANCHORED — rotates via RunService script during play)
local function spinner(pos, color, speed)
	local p = mk({pos=pos, size=Vector3.new(18,1,1.4), color=color or HOT_PINK, mat=Enum.Material.Neon, name="Spinner"})
	local s = Instance.new("Script")
	s.Source = string.format([[
		local RS = game:GetService("RunService")
		local p = script.Parent
		local t = 0
		RS.Heartbeat:Connect(function(dt)
			t = t + dt * %g
			p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, t, 0)
		end)
		p.Touched:Connect(function(hit)
			local h = hit.Parent:FindFirstChildWhichIsA("Humanoid")
			if h then h.Health = 0 end
		end)
	]], speed or 1.6)
	s.Parent = p
	return p
end

-- Moving platform (Anchored, tweens via TweenService during play)
local function movPlatform(pos, color, range, speed)
	local p = mk({pos=pos, size=Vector3.new(7,2,7), color=color or LAVENDER, name="MovPlatform"})
	local s = Instance.new("Script")
	s.Source = string.format([[
		local TS = game:GetService("TweenService")
		local p = script.Parent
		local orig = p.Position
		local info = TweenInfo.new(%g, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TS:Create(p, info, {Position = orig + Vector3.new(%d,0,0)}):Play()
	]], speed, range)
	s.Parent = p
	return p
end

local function checkpoint(pos, num)
	mk({pos=pos, size=Vector3.new(0.5,9,0.5), color=WHITE, mat=Enum.Material.Metal})
	local flag = mk({pos=pos+Vector3.new(2.5,3,0), size=Vector3.new(5,2.5,0.25), color=HOT_PINK, mat=Enum.Material.Neon, name="CP_"..num})
	local s = Instance.new("Script")
	s.Source = string.format([[
		local db = {}
		script.Parent.Touched:Connect(function(hit)
			local pl = game.Players:GetPlayerFromCharacter(hit.Parent)
			if not pl or db[pl.UserId] then return end
			db[pl.UserId] = true
			local ls = pl:FindFirstChild("leaderstats")
			if ls then ls.Stage.Value = math.max(ls.Stage.Value, %d) end
			task.wait(2) db[pl.UserId] = nil
		end)
	]], num)
	s.Parent = flag
end

-- ── Femboy NPC ────────────────────────────────────────────────────────────────
-- Simple humanoid-shaped decoration model
local function npc(pos, hairCol, outfitCol)
	hairCol   = hairCol   or LAVENDER
	outfitCol = outfitCol or PINK
	local function b(p,s,c,m,sh)
		local part = Instance.new("Part")
		part.Anchored = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CastShadow = true
		part.Position = p; part.Size = s; part.Color = c
		part.Material = m or Enum.Material.SmoothPlastic
		if sh then part.Shape = sh end
		part.Parent = map
		return part
	end
	-- Shoes
	b(pos+Vector3.new(-0.5,0.5,0.1),  Vector3.new(0.9,1,1.1), Color3.fromRGB(60,40,80))
	b(pos+Vector3.new(0.5,0.5,0.1),   Vector3.new(0.9,1,1.1), Color3.fromRGB(60,40,80))
	-- Legs (thigh-highs: pink bottom, skin top)
	b(pos+Vector3.new(-0.5,1.6,0),    Vector3.new(0.85,1.2,0.85), HOT_PINK)
	b(pos+Vector3.new(0.5,1.6,0),     Vector3.new(0.85,1.2,0.85), HOT_PINK)
	b(pos+Vector3.new(-0.5,2.6,0),    Vector3.new(0.8,0.8,0.8),  SKIN)
	b(pos+Vector3.new(0.5,2.6,0),     Vector3.new(0.8,0.8,0.8),  SKIN)
	-- Skirt (wide flat block)
	b(pos+Vector3.new(0,3.4,0),       Vector3.new(2.8,1.0,2.8),  outfitCol)
	-- Torso
	b(pos+Vector3.new(0,4.6,0),       Vector3.new(2.0,1.8,1.0),  WHITE)
	-- Collar bow
	bow(pos+Vector3.new(0,5.1,-0.6), HOT_PINK)
	-- Arms
	b(pos+Vector3.new(-1.4,4.3,0),    Vector3.new(0.7,1.8,0.7),  SKIN)
	b(pos+Vector3.new(1.4,4.3,0),     Vector3.new(0.7,1.8,0.7),  SKIN)
	-- Gloves/cuffs
	b(pos+Vector3.new(-1.4,3.5,0),    Vector3.new(0.8,0.6,0.8),  HOT_PINK)
	b(pos+Vector3.new(1.4,3.5,0),     Vector3.new(0.8,0.6,0.8),  HOT_PINK)
	-- Neck
	b(pos+Vector3.new(0,5.7,0),       Vector3.new(0.6,0.5,0.6),  SKIN)
	-- Head (sphere)
	b(pos+Vector3.new(0,6.6,0),       Vector3.new(1.8,1.8,1.8),  SKIN, nil, Enum.PartType.Ball)
	-- Hair body (sphere slightly larger)
	b(pos+Vector3.new(0,7.0,0),       Vector3.new(2.1,1.6,2.1),  hairCol, nil, Enum.PartType.Ball)
	-- Hair bang (front floof)
	b(pos+Vector3.new(0,6.5,-0.95),   Vector3.new(1.4,0.9,0.6),  hairCol)
	-- Cat ears
	for _, sx in ipairs({-0.75, 0.75}) do
		local we = Instance.new("WedgePart")
		we.Anchored = true
		we.Size = Vector3.new(0.55,1.2,0.55)
		we.Position = pos + Vector3.new(sx, 7.9, 0)
		we.Color = HOT_PINK
		we.Material = Enum.Material.SmoothPlastic
		we.TopSurface = Enum.SurfaceType.Smooth
		we.BottomSurface = Enum.SurfaceType.Smooth
		we.Parent = map
	end
	-- Blush
	b(pos+Vector3.new(-0.7,6.5,-0.9), Vector3.new(0.55,0.3,0.25), HOT_PINK, Enum.Material.Neon)
	b(pos+Vector3.new(0.7,6.5,-0.9),  Vector3.new(0.55,0.3,0.25), HOT_PINK, Enum.Material.Neon)
	-- Eye dots
	b(pos+Vector3.new(-0.45,6.7,-0.91), Vector3.new(0.25,0.3,0.15), Color3.fromRGB(40,20,60), Enum.Material.Neon)
	b(pos+Vector3.new(0.45,6.7,-0.91),  Vector3.new(0.25,0.3,0.15), Color3.fromRGB(40,20,60), Enum.Material.Neon)
	-- Smile
	b(pos+Vector3.new(0,6.3,-0.91),     Vector3.new(0.5,0.2,0.1), Color3.fromRGB(200,80,120), Enum.Material.Neon)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  MAP
--  All platform centers at Y=1, top surface at Y=2.
--  Spawn platform top = Y=2. Front edge = Z = -11 (size 22).
--  Player jumps max ~16 studs horizontal. Gaps kept under 8 studs.
-- ══════════════════════════════════════════════════════════════════════════════

-- SpawnLocation (placed ON the spawn pad so player spawns correctly)
local sl = Instance.new("SpawnLocation")
sl.Name = "FemboySpawn"
sl.Anchored = true
sl.Size = Vector3.new(6,1,6)
sl.Position = Vector3.new(0, 2.5, 5)
sl.Color = HOT_PINK
sl.Material = Enum.Material.Neon
sl.TopSurface = Enum.SurfaceType.Smooth
sl.BottomSurface = Enum.SurfaceType.Smooth
sl.Duration = 0
sl.AllowTeamChangeOnTouch = false
sl.Parent = workspace

-- ── Section 0: Spawn Platform ─────────────────────────────────────────────────
local spawnPad = mk({name="SpawnPad", pos=Vector3.new(0,1,0), size=Vector3.new(22,2,22), color=PINK})
catEars(spawnPad)

sign("✧ FEMBOY OBBY ✧",     Vector3.new(0, 6, -11.5), HOT_PINK)
sign("✧ FEMBOY OBBY ✧",     Vector3.new(0, 6, 11.5),  HOT_PINK)

-- NPCs on spawn
npc(Vector3.new(-7, 2, -4), LAVENDER,  PINK)
npc(Vector3.new(7,  2, -4), HOT_PINK,  LAVENDER)

-- Decorations
heart(Vector3.new(-9, 5.5, 0), HOT_PINK)
heart(Vector3.new(9,  5.5, 0), LAVENDER)
bow(Vector3.new(0, 5,  -9),  HOT_PINK)
bow(Vector3.new(-5,4.5, 6),  LAVENDER)
bow(Vector3.new(5, 4.5, 6),  LAVENDER)

-- Direction arrow (neon pink arrow pointing toward first jump)
mk({pos=Vector3.new(0,2.1,-7), size=Vector3.new(1.5,0.25,3), color=HOT_PINK, mat=Enum.Material.Neon})
local ah = Instance.new("WedgePart")
ah.Anchored=true; ah.Size=Vector3.new(2.5,0.25,2); ah.Position=Vector3.new(0,2.1,-9.2)
ah.Color=HOT_PINK; ah.Material=Enum.Material.Neon
ah.TopSurface=Enum.SurfaceType.Smooth; ah.BottomSurface=Enum.SurfaceType.Smooth
ah.Parent=map

-- ── Section 1: Stepping Stones ─────────────────────────────────────────────────
--  Spawn front edge Z=-11. First stone near edge Z=-12 (gap=1, basically walking).
--  Gradually get harder: stones get smaller & offset increases.
local s1data = {
	-- {xOff, Z,   sizeX, sizeZ, color}
	{0,   -16,  8,   6,   PINK},         -- very easy intro stone (big, straight ahead)
	{-4,  -25,  6,   5,   LAVENDER},
	{4,   -33,  6,   5,   PASTEL_BLUE},
	{-3,  -41,  6,   5,   PINK},
	{4,   -49,  5,   5,   LAVENDER},
	{0,   -58,  9,   7,   PINK},          -- rest pad
}
for i, d in ipairs(s1data) do
	local p = mk({pos=Vector3.new(d[1],1,d[2]), size=Vector3.new(d[3],2,d[4]), color=d[5]})
	if i == 6 then
		catEars(p)
		npc(Vector3.new(d[1]+3, 2, d[2]), PINK, LAVENDER)
	end
	if i % 2 == 0 then bow(Vector3.new(d[1], 3.5, d[2]), HOT_PINK) end
end

checkpoint(Vector3.new(0, 1, -60), 1)
sign("Checkpoint 1! OwO", Vector3.new(6, 5, -60), GOLD)

-- ── Section 2: Moving Platforms ───────────────────────────────────────────────
--  Rest pad far edge = Z=-61. First mover center at Z=-70.
sign("~ Float Like a Kitty ~", Vector3.new(0,7,-68), LAVENDER)

movPlatform(Vector3.new(0, 1, -72),  LAVENDER,    9, 1.8)
movPlatform(Vector3.new(0, 1, -84),  HOT_PINK,    7, 1.4)
movPlatform(Vector3.new(0, 1, -96),  PASTEL_BLUE, 10, 2.0)
movPlatform(Vector3.new(0, 1, -108), SOFT_PURPLE,  8, 1.6)

-- Landing pad after movers (center Z=-118, near edge Z=-121)
local landPad = mk({pos=Vector3.new(0,1,-118), size=Vector3.new(10,2,7), color=PINK})
catEars(landPad)
npc(Vector3.new(4, 2, -118), LAVENDER, HOT_PINK)
checkpoint(Vector3.new(0, 1, -124), 2)
sign("Checkpoint 2! UwU", Vector3.new(6, 5, -124), GOLD)

-- ── Section 3: Cat Ear Tower Climb ────────────────────────────────────────────
--  Landing pad top edge Z=-122. Tower starts at Z=-128, climbs Y from 1 → 36.
sign("Climb the Tower, Kitty! ★", Vector3.new(0, 7, -130), HOT_PINK)

local tSteps = {
	{6,   6,  -130, PINK},
	{-6,  11, -133, LAVENDER},
	{6,   16, -136, HOT_PINK},
	{-6,  21, -139, PASTEL_BLUE},
	{6,   26, -142, LAVENDER},
	{-6,  31, -145, PINK},
	{0,   36, -148, HOT_PINK},   -- tower top (wider rest)
}
for i, t in ipairs(tSteps) do
	local p = mk({pos=Vector3.new(t[1],t[2],t[3]), size=Vector3.new(7,2,6), color=t[4]})
	catEars(p)
	if i % 2 == 0 then bow(Vector3.new(t[1],t[2]+2.5,t[3]), t[4]) end
end

npc(Vector3.new(3, 37, -148), HOT_PINK, PINK)
checkpoint(Vector3.new(0, 36, -153), 3)
sign("Checkpoint 3! ★ Halfway!", Vector3.new(6, 41, -153), GOLD)

-- ── Section 4: Spinner Laser Gauntlet ─────────────────────────────────────────
--  Tower top Y=37. Spinners float at Y=38.5, safe pads at Y=37.
local spY = 37
local spZ = -162

sign("!!! DANGER ZONE !!!", Vector3.new(0, spY+5, spZ+4), RED_WARN)

-- Safe pads (solid white platforms the player stands on between spinners)
for _, z in ipairs({spZ, spZ-16, spZ-32, spZ-48}) do
	mk({pos=Vector3.new(0, spY, z), size=Vector3.new(6,2,5), color=WHITE})
end

-- Spinners (anchored, rotate in play mode)
spinner(Vector3.new(0, spY+2, spZ-8),  HOT_PINK,    1.8)
spinner(Vector3.new(0, spY+2, spZ-24), SOFT_PURPLE,  1.4)
spinner(Vector3.new(0, spY+2, spZ-40), HOT_PINK,    2.4)

checkpoint(Vector3.new(0, spY, spZ-56), 4)
sign("Checkpoint 4! ★★", Vector3.new(6, spY+5, spZ-56), GOLD)

-- ── Section 5: Rainbow Neon Bridge ────────────────────────────────────────────
local rbZ = spZ - 68
local rbY = spY

sign("~ Walk the Rainbow Path ~", Vector3.new(0, rbY+6, rbZ+2), GOLD)

local rbCols = {
	Color3.fromRGB(255,150,180), Color3.fromRGB(255,200,130),
	Color3.fromRGB(180,255,170), Color3.fromRGB(150,210,255),
	Color3.fromRGB(200,155,255), Color3.fromRGB(255,155,200),
	Color3.fromRGB(255,215,130),
}
for i, c in ipairs(rbCols) do
	mk({pos=Vector3.new(0, rbY, rbZ-(i*6)), size=Vector3.new(3.5,2,6), color=c, mat=Enum.Material.Neon})
end
-- Small heart floats above rainbow bridge
for i = 1, 4 do
	heart(Vector3.new((i%2==0 and 4 or -4), rbY+5, rbZ-(i*12)), HOT_PINK)
end

-- ── Section 6: Win Platform ────────────────────────────────────────────────────
local wpZ = rbZ - (#rbCols * 6) - 14
local wpY = rbY

local winPad = mk({name="WinPlatform", pos=Vector3.new(0,wpY,wpZ), size=Vector3.new(26,2,26), color=GOLD, mat=Enum.Material.Neon})
catEars(winPad)

sign("✧  YOU WIN!  ✧",         Vector3.new(0, wpY+8, wpZ),     GOLD)
sign("Stage Clear! ~  UwU  ~  ★★★", Vector3.new(0, wpY+5, wpZ+13.5), HOT_PINK)

-- Three NPCs celebrating
npc(Vector3.new(-8, wpY+2, wpZ),   LAVENDER, PINK)
npc(Vector3.new(0,  wpY+2, wpZ-6), HOT_PINK, LAVENDER)
npc(Vector3.new(8,  wpY+2, wpZ),   PINK,     HOT_PINK)

-- Hearts + bows scattered
for _, ox in ipairs({-9,-4,0,4,9}) do heart(Vector3.new(ox, wpY+6, wpZ+4), HOT_PINK) end
for _, ox in ipairs({-6, 0, 6})    do bow(Vector3.new(ox,  wpY+5, wpZ-3), GOLD)        end

-- Win detection + GUI
local ws = Instance.new("Script")
ws.Source = [[
	local part = script.Parent
	local db   = {}
	part.Touched:Connect(function(hit)
		local pl = game.Players:GetPlayerFromCharacter(hit.Parent)
		if not pl or db[pl.UserId] then return end
		db[pl.UserId] = true

		local sg = Instance.new("ScreenGui", pl.PlayerGui)
		sg.Name = "WinScreen"
		local frame = Instance.new("Frame", sg)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position    = UDim2.new(0.5,0,0.5,0)
		frame.Size        = UDim2.new(0.5,0,0.25,0)
		frame.BackgroundColor3 = Color3.fromRGB(255,105,180)
		frame.BorderSizePixel  = 0
		local corner = Instance.new("UICorner", frame)
		corner.CornerRadius = UDim.new(0.12, 0)
		local lbl = Instance.new("TextLabel", frame)
		lbl.Size = UDim2.new(1,0,1,0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "Stage Clear! UwU"
		lbl.TextScaled = true
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Font = Enum.Font.GothamBold

		task.wait(5)
		sg:Destroy()
		db[pl.UserId] = nil
	end)
]]
ws.Parent = winPad

-- ── Done ──────────────────────────────────────────────────────────────────────
print("✧ FemBoy Obby Level 1 v2 built! ✧")
print("NEXT STEPS:")
print("  1. Delete the default Baseplate (Explorer > Workspace > Baseplate > Delete)")
print("  2. Add Leaderboard.luau content into a Script in ServerScriptService")
print("  3. Press PLAY to test spinners & moving platforms (they dont move in edit mode)")
