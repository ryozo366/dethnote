-- Place in: StarterPlayer -> StarterPlayerScripts (as a LocalScript)
-- Adds a small heart-shaped donate button (bottom-right) that opens a panel
-- with 4 donate options + a list of all donators. Pastel pink theme.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local PRODUCTS = {
	{ ProductPrice = 10,  ProductId = 3589242520 },
	{ ProductPrice = 20,  ProductId = 3589242795 },
	{ ProductPrice = 50,  ProductId = 3589242932 },
	{ ProductPrice = 100, ProductId = 3589243022 },
}

local remotes = ReplicatedStorage:WaitForChild("LavaRunRemotes")
local DonatorsUpdate = remotes:WaitForChild("DonatorsUpdate")
local GetDonators    = remotes:WaitForChild("GetDonators")
local PromptDonate   = remotes:WaitForChild("PromptDonate")

----------------------------------------------------------------
-- Palette (matches the leaderboard)
----------------------------------------------------------------
local PINK_BG    = Color3.fromRGB(255, 228, 235)
local PINK_PANEL = Color3.fromRGB(255, 209, 220)
local PINK_DARK  = Color3.fromRGB(232, 145, 170)
local PINK_TEXT  = Color3.fromRGB(120, 60, 90)
local WHITE      = Color3.fromRGB(255, 255, 255)
local GOLD       = Color3.fromRGB(212, 175, 55)
local SILVER     = Color3.fromRGB(192, 192, 192)
local BRONZE     = Color3.fromRGB(205, 127, 50)

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 12) c.Parent = p return c end
local function stroke(p, c, t) local s = Instance.new("UIStroke") s.Color = c or PINK_DARK s.Thickness = t or 2 s.Parent = p return s end
local function gradient(p, a, b, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b)})
	g.Rotation = rot or 90
	g.Parent = p
	return g
end

----------------------------------------------------------------
-- ScreenGui
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "DonateUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

----------------------------------------------------------------
-- Donate button (bottom-right)
----------------------------------------------------------------
local btn = Instance.new("TextButton")
btn.Name = "DonateButton"
btn.AnchorPoint = Vector2.new(1, 1)
btn.Position = UDim2.new(1, -20, 1, -20)
btn.Size = UDim2.fromOffset(120, 56)
btn.BackgroundColor3 = PINK_PANEL
btn.BorderSizePixel = 0
btn.AutoButtonColor = true
btn.Font = Enum.Font.GothamBold
btn.TextScaled = true
btn.TextColor3 = WHITE
btn.Text = "DONATE"
btn.Parent = gui
corner(btn, 16)
stroke(btn, PINK_DARK, 2)
gradient(btn, PINK_PANEL, PINK_DARK, 90)

local heart = Instance.new("TextLabel")
heart.BackgroundTransparency = 1
heart.Size = UDim2.fromOffset(28, 28)
heart.Position = UDim2.new(0, 6, 0.5, -14)
heart.Font = Enum.Font.GothamBold
heart.TextScaled = true
heart.TextColor3 = WHITE
heart.Text = "<3"
heart.Parent = btn

local btnPad = Instance.new("UIPadding")
btnPad.PaddingLeft = UDim.new(0, 30)
btnPad.Parent = btn

----------------------------------------------------------------
-- Modal panel (hidden by default)
----------------------------------------------------------------
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Visible = false
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.AutoButtonColor = false
backdrop.Text = ""
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(440, 540)
panel.BackgroundColor3 = PINK_BG
panel.BorderSizePixel = 0
panel.Parent = backdrop
corner(panel, 18)
stroke(panel, PINK_DARK, 2)
gradient(panel, PINK_BG, PINK_PANEL, 135)

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = PINK_PANEL
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 18)
gradient(header, PINK_PANEL, PINK_DARK, 90)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 18)
headerFix.Position = UDim2.new(0, 0, 1, -18)
headerFix.BackgroundColor3 = PINK_DARK
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = WHITE
title.Text = "SUPPORT THE GAME <3"
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -10, 0.5, 0)
closeBtn.Size = UDim2.fromOffset(36, 36)
closeBtn.BackgroundColor3 = WHITE
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.TextColor3 = PINK_DARK
closeBtn.Parent = header
corner(closeBtn, 10)

----------------------------------------------------------------
-- Product buttons row (explicit positioning, no UIListLayout)
----------------------------------------------------------------
local row = Instance.new("Frame")
row.Name = "ProductRow"
row.Size = UDim2.new(1, -24, 0, 80)
row.Position = UDim2.new(0, 12, 0, 70)
row.BackgroundTransparency = 1
row.Parent = panel

local function makeProductButton(price, id, index, total)
	local count = total or 4
	local pad = 8
	local b = Instance.new("TextButton")
	b.Name = "Buy_" .. tostring(price)
	-- 1/count width minus padding share, positioned by index (0-based)
	b.Size = UDim2.new(1 / count, -pad, 1, 0)
	b.Position = UDim2.new((index - 1) / count, pad / 2, 0, 0)
	b.BackgroundColor3 = PINK_PANEL
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Text = ""
	b.Parent = row
	corner(b, 12)
	stroke(b, PINK_DARK, 2)
	gradient(b, PINK_BG, PINK_PANEL, 90)

	local amount = Instance.new("TextLabel")
	amount.BackgroundTransparency = 1
	amount.Size = UDim2.new(1, 0, 0.6, 0)
	amount.Position = UDim2.new(0, 0, 0, 6)
	amount.Font = Enum.Font.GothamBlack
	amount.TextScaled = true
	amount.TextColor3 = PINK_TEXT
	amount.Text = tostring(price) .. " R$"
	amount.Parent = b

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(1, 0, 0.3, 0)
	sub.Position = UDim2.new(0, 0, 0.65, 0)
	sub.Font = Enum.Font.Gotham
	sub.TextScaled = true
	sub.TextColor3 = PINK_DARK
	sub.Text = "Donate"
	sub.Parent = b

	b.MouseButton1Click:Connect(function()
		PromptDonate:FireServer(id)
	end)
end

----------------------------------------------------------------
-- Donator list
----------------------------------------------------------------
local listTitle = Instance.new("TextLabel")
listTitle.BackgroundTransparency = 1
listTitle.Size = UDim2.new(1, -24, 0, 26)
listTitle.Position = UDim2.new(0, 12, 0, 160)
listTitle.Font = Enum.Font.GothamBold
listTitle.TextScaled = true
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.TextColor3 = PINK_TEXT
listTitle.Text = "TOP DONATORS"
listTitle.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -200)
scroll.Position = UDim2.new(0, 12, 0, 188)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = PINK_DARK
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scroll

local function rankColor(r) if r==1 then return GOLD elseif r==2 then return SILVER elseif r==3 then return BRONZE else return PINK_PANEL end end

local function makeRow(rank, name, robux)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -4, 0, 36)
	f.BackgroundColor3 = (rank % 2 == 0) and PINK_BG or WHITE
	f.BackgroundTransparency = 0.1
	f.BorderSizePixel = 0
	f.LayoutOrder = rank
	f.Parent = scroll
	corner(f, 8)

	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromOffset(36, 28)
	badge.Position = UDim2.new(0, 4, 0.5, -14)
	badge.BackgroundColor3 = rankColor(rank)
	badge.BorderSizePixel = 0
	badge.Parent = f
	corner(badge, 6)

	local rt = Instance.new("TextLabel")
	rt.BackgroundTransparency = 1
	rt.Size = UDim2.fromScale(1, 1)
	rt.Font = Enum.Font.GothamBold
	rt.TextScaled = true
	rt.TextColor3 = (rank <= 3) and WHITE or PINK_TEXT
	rt.Text = "#" .. rank
	rt.Parent = badge

	local nm = Instance.new("TextLabel")
	nm.BackgroundTransparency = 1
	nm.Position = UDim2.new(0, 48, 0, 0)
	nm.Size = UDim2.new(0.55, -52, 1, 0)
	nm.Font = Enum.Font.GothamMedium
	nm.TextScaled = true
	nm.TextXAlignment = Enum.TextXAlignment.Left
	nm.TextColor3 = PINK_TEXT
	nm.Text = name
	nm.Parent = f

	local r = Instance.new("TextLabel")
	r.BackgroundTransparency = 1
	r.Position = UDim2.new(0.55, 0, 0, 0)
	r.Size = UDim2.new(0.45, -8, 1, 0)
	r.Font = Enum.Font.GothamBold
	r.TextScaled = true
	r.TextXAlignment = Enum.TextXAlignment.Right
	r.TextColor3 = PINK_DARK
	r.Text = robux .. " R$"
	r.Parent = f
end

local function render(list)
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end
	if not list or #list == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.Font = Enum.Font.Gotham
		empty.TextScaled = true
		empty.TextColor3 = PINK_DARK
		empty.Text = "No donators yet - be the first <3"
		empty.Parent = scroll
		return
	end
	for i, e in ipairs(list) do
		makeRow(i, e.name, e.robux)
	end
end

DonatorsUpdate.OnClientEvent:Connect(render)

----------------------------------------------------------------
-- Open / close
----------------------------------------------------------------
local function open()
	backdrop.Visible = true
	-- refresh list
	task.spawn(function()
		local ok, list = pcall(function() return GetDonators:InvokeServer() end)
		if ok then render(list) end
	end)
end
local function close() backdrop.Visible = false end

btn.MouseButton1Click:Connect(open)
closeBtn.MouseButton1Click:Connect(close)
backdrop.MouseButton1Click:Connect(close)
panel.MouseButton1Click = nil -- block clicks bubbling? not needed for Frame

----------------------------------------------------------------
-- Build product buttons
----------------------------------------------------------------
print("[Donate] Building", #PRODUCTS, "product buttons")
for i, p in ipairs(PRODUCTS) do
	makeProductButton(p.ProductPrice, p.ProductId, i, #PRODUCTS)
end

-- Remove any duplicate ScreenGuis from previous script reloads
for _, g in ipairs(pg:GetChildren()) do
	if g.Name == "DonateUI" and g ~= gui then g:Destroy() end
end
