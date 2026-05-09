--!strict
-- Place in: ServerScriptService (as a Script)
-- Handles donation purchases and a global donator leaderboard.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local Marketplace      = game:GetService("MarketplaceService")

----------------------------------------------------------------
-- Products
----------------------------------------------------------------
local PRODUCTS = {
	{ ProductPrice = 10,  ProductId = 3589242520 },
	{ ProductPrice = 20,  ProductId = 3589242795 },
	{ ProductPrice = 50,  ProductId = 3589242932 },
	{ ProductPrice = 100, ProductId = 3589243022 },
}

local idToPrice: {[number]: number} = {}
for _, p in ipairs(PRODUCTS) do idToPrice[p.ProductId] = p.ProductPrice end

local TOP_LIMIT = 100

----------------------------------------------------------------
-- Remotes (reuse the LavaRunRemotes folder if present)
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

local DonateProducts = makeRemote("DonateProducts", "RemoteFunction") :: RemoteFunction
local DonatorsUpdate = makeRemote("DonatorsUpdate", "RemoteEvent")    :: RemoteEvent
local GetDonators    = makeRemote("GetDonators",    "RemoteFunction") :: RemoteFunction
local PromptDonate   = makeRemote("PromptDonate",   "RemoteEvent")    :: RemoteEvent

DonateProducts.OnServerInvoke = function(_player) return PRODUCTS end

----------------------------------------------------------------
-- DataStores
----------------------------------------------------------------
local donateStore     = DataStoreService:GetOrderedDataStore("Donators_v1")
local donateNameStore = DataStoreService:GetDataStore("DonatorNames_v1")

local function loadDonators(): {{name: string, robux: number}}
	local result = {}
	local ok, pages = pcall(function()
		return donateStore:GetSortedAsync(false, TOP_LIMIT) -- descending = highest donor first
	end)
	if not ok or not pages then return result end
	local page = pages:GetCurrentPage()
	for _, entry in ipairs(page) do
		local userId = tostring(entry.key)
		local nm = "Player"
		local ok2, val = pcall(function() return donateNameStore:GetAsync(userId) end)
		if ok2 and typeof(val) == "string" then nm = val end
		table.insert(result, { name = nm, robux = entry.value })
	end
	return result
end

local function broadcastDonators()
	DonatorsUpdate:FireAllClients(loadDonators())
end

GetDonators.OnServerInvoke = function(_player) return loadDonators() end

----------------------------------------------------------------
-- Prompt purchase from client
----------------------------------------------------------------
PromptDonate.OnServerEvent:Connect(function(player, productId)
	if typeof(productId) ~= "number" then return end
	if not idToPrice[productId] then return end
	pcall(function()
		Marketplace:PromptProductPurchase(player, productId)
	end)
end)

----------------------------------------------------------------
-- ProcessReceipt
----------------------------------------------------------------
Marketplace.ProcessReceipt = function(receipt)
	local price = idToPrice[receipt.ProductId]
	if not price then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local userId = receipt.PlayerId
	local key = tostring(userId)

	-- Idempotency: ensure we only credit each PurchaseId once per player.
	local idemKey = "purch_" .. tostring(receipt.PurchaseId)
	local idemStore = DataStoreService:GetDataStore("DonatePurchases_v1")
	local already
	local ok0 = pcall(function()
		already = idemStore:GetAsync(idemKey)
	end)
	if not ok0 then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not already then
		local ok = pcall(function()
			donateStore:UpdateAsync(key, function(prev)
				return (prev or 0) + price
			end)
		end)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		pcall(function() idemStore:SetAsync(idemKey, true) end)
	end

	-- Save player name (best effort)
	pcall(function()
		local p = Players:GetPlayerByUserId(userId)
		if p then donateNameStore:SetAsync(key, p.Name) end
	end)

	broadcastDonators()
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

----------------------------------------------------------------
-- Player join: send current list
----------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	task.delay(2, function()
		DonatorsUpdate:FireClient(player, loadDonators())
	end)
end)

task.spawn(broadcastDonators)
