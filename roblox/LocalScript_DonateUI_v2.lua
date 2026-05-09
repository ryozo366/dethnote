-- Place in: StarterPlayer -> StarterPlayerScripts (as a LocalScript)
-- Self-contained donate UI: button bottom-right, modal with 4 buy buttons + donator list.

print("[Donate] LocalScript starting...")

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Marketplace       = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- Remove any old donate UIs left from previous script versions
for _, g in ipairs(pg:GetChildren()) do
	if g.Name == "DonateUI" or g.Name == "DonateUI_v2" then g:Destroy() end
end

local PRODUCTS = {
	{ price = 10,  id = 3589242520 },
	{ price = 20,  id = 3589242795 },
	{ price = 50,  id = 3589242932 },
	{ price = 100, id = 3589243022 },
}

----------------------------------------------------------------
-- Colors
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

----------------------------------------------------------------
-- Root GUI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "DonateUI_v2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

----------------------------------------------------------------
-- Open button (bottom-right)
----------------------------------------------------------------
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenButton"
openBtn.AnchorPoint = Vector2.new(1, 1)
openBtn.Position = UDim2.new(1, -20, 1, -20)
openBtn.Size = UDim2.fromOffset(140, 56)
openBtn.BackgroundColor3 = PINK_DARK
openBtn.BorderSizePixel = 0
openBtn.Font = Enum.Font.GothamBold
openBtn.TextScaled = true
openBtn.TextColor3 = WHITE
openBtn.Text = "<3 DONATE"
openBtn.Parent = gui
corner(openBtn, 16)
stroke(openBtn, WHITE, 2)

----------------------------------------------------------------
-- Modal
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
panel.Size = UDim2.fromOffset(460, 560)
panel.BackgroundColor3 = PINK_BG
panel.BorderSizePixel = 0
panel.Parent = backdrop
corner(panel, 18)
stroke(panel, PINK_DARK, 2)

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = PINK_DARK
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 18)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 18)
headerFix.Position = UDim2.new(0, 0, 1, -18)
headerFix.BackgroundColor3 = PINK_DARK
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 0)
title.Size = UDim2.new(1, -70, 1, 0)
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
-- Donate buttons (4 across, explicit positions)
----------------------------------------------------------------
local panelW = 460
local rowMargin = 14
local rowY = 76
local rowH = 90
local count = #PRODUCTS
local available = panelW - rowMargin * 2
local gap = 8
local btnW = (available - gap * (count - 1)) / count

print("[Donate] btnW =", btnW, "available =", available)

local function tryBuy(productId)
	print("[Donate] Prompting purchase for", productId)
	local ok, err = pcall(function()
		Marketplace:PromptProductPurchase(player, productId)
	end)
	if not ok then warn("[Donate] PromptProductPurchase failed:", err) end
end

for i, prod in ipairs(PRODUCTS) do
	local b = Instance.new("TextButton")
	b.Name = "Buy_" .. tostring(prod.price)
	b.Size = UDim2.fromOffset(btnW, rowH)
	b.Position = UDim2.fromOffset(rowMargin + (i - 1) * (btnW + gap), rowY)
	b.BackgroundColor3 = PINK_PANEL
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Text = ""
	b.Parent = panel
	corner(b, 12)
	stroke(b, PINK_DARK, 2)

	local amount = Instance.new("TextLabel")
	amount.BackgroundTransparency = 1
	amount.Size = UDim2.new(1, 0, 0.6, 0)
	amount.Position = UDim2.new(0, 0, 0, 4)
	amount.Font = Enum.Font.GothamBlack
	amount.TextScaled = true
	amount.TextColor3 = PINK_TEXT
	amount.Text = tostring(prod.price) .. " R$"
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

	b.MouseButton1Click:Connect(function() tryBuy(prod.id) end)
	print("[Donate] Created button", i, "price", prod.price)
end

----------------------------------------------------------------
-- Donator list
----------------------------------------------------------------
local listTitle = Instance.new("TextLabel")
listTitle.BackgroundTransparency = 1
listTitle.Position = UDim2.fromOffset(rowMargin, rowY + rowH + 16)
listTitle.Size = UDim2.new(1, -rowMargin * 2, 0, 26)
listTitle.Font = Enum.Font.GothamBold
listTitle.TextScaled = true
listTitle.TextXAlignment = Enum.TextXAlignment.Left
listTitle.TextColor3 = PINK_TEXT
listTitle.Text = "TOP DONATORS"
listTitle.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(rowMargin, rowY + rowH + 50)
scroll.Size = UDim2.new(1, -rowMargin * 2, 1, -(rowY + rowH + 64))
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

local function rankColor(r)
	if r == 1 then return GOLD end
	if r == 2 then return SILVER end
	if r == 3 then return BRONZE end
	return PINK_PANEL
end

local function clearList()
	for _, c in ipairs(scroll:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
end

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
	clearList()
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

render(nil)

-- Try to subscribe to live donator updates if the server provides them
task.spawn(function()
	local remotes = ReplicatedStorage:FindFirstChild("LavaRunRemotes")
	if not remotes then return end
	local upd = remotes:WaitForChild("DonatorsUpdate", 5)
	local getF = remotes:WaitForChild("GetDonators", 5)
	if upd then upd.OnClientEvent:Connect(render) end
	if getF then
		local ok, list = pcall(function() return getF:InvokeServer() end)
		if ok then render(list) end
	end
end)

----------------------------------------------------------------
-- Open / close
----------------------------------------------------------------
openBtn.MouseButton1Click:Connect(function()
	backdrop.Visible = true
end)
closeBtn.MouseButton1Click:Connect(function()
	backdrop.Visible = false
end)
backdrop.MouseButton1Click:Connect(function(x, y)
	-- only close if clicked outside the panel
	local abs = panel.AbsolutePosition
	local size = panel.AbsoluteSize
	local mx, my = x or 0, y or 0
	if mx < abs.X or mx > abs.X + size.X or my < abs.Y or my > abs.Y + size.Y then
		backdrop.Visible = false
	end
end)

print("[Donate] UI ready. PRODUCTS:", #PRODUCTS)
