-- Place in: StarterPlayer -> StarterPlayerScripts (as a LocalScript)
-- Press F to toggle flight. WASD to move, Space = up, Shift = down, mouse to look.

local Players      = game:GetService("Players")
local UserInput    = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")

local FLY_SPEED    = 80
local TOGGLE_KEY   = Enum.KeyCode.F

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local bodyVel: BodyVelocity? = nil
local bodyGyro: BodyGyro? = nil
local renderConn: RBXScriptConnection? = nil

local function getRoot(): BasePart?
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function stopFlying()
	flying = false
	if renderConn then renderConn:Disconnect() renderConn = nil end
	if bodyVel then bodyVel:Destroy() bodyVel = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
	end
end

local function startFlying()
	local root = getRoot()
	if not root then return end
	local hum = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	flying = true
	hum.PlatformStand = true

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVel.Velocity = Vector3.zero
	bodyVel.Parent = root

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bodyGyro.P = 1e4
	bodyGyro.D = 500
	bodyGyro.CFrame = root.CFrame
	bodyGyro.Parent = root

	renderConn = RunService.RenderStepped:Connect(function()
		local r = getRoot()
		if not r or not bodyVel or not bodyGyro then return end

		local move = Vector3.zero
		local look = camera.CFrame.LookVector
		local right = camera.CFrame.RightVector
		if UserInput:IsKeyDown(Enum.KeyCode.W) then move += look end
		if UserInput:IsKeyDown(Enum.KeyCode.S) then move -= look end
		if UserInput:IsKeyDown(Enum.KeyCode.D) then move += right end
		if UserInput:IsKeyDown(Enum.KeyCode.A) then move -= right end
		if UserInput:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
		if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.yAxis end

		if move.Magnitude > 0 then move = move.Unit * FLY_SPEED end
		bodyVel.Velocity = move
		bodyGyro.CFrame = CFrame.new(r.Position, r.Position + look)
	end)
end

UserInput.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == TOGGLE_KEY then
		if flying then stopFlying() else startFlying() end
	end
end)

player.CharacterAdded:Connect(function() stopFlying() end)
