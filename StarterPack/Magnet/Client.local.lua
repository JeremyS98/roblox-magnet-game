-- Magnet Tool Client.local.lua  (vPowerAim+WorldBar, thin+long, body-aligned, random speed)
-- Bar next to player body • Bottom-up fill • Random speed per attempt (0.5..2.0)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local tool = script.Parent
tool.RequiresHandle = true

-- Remotes
local CastMagnet    = RS:WaitForChild("CastMagnet")
local RequestReelIn = RS:WaitForChild("RequestReelIn")
local OpenReel      = RS:WaitForChild("OpenReel")
local ReelEnded     = RS:WaitForChild("ReelEnded")

local function uiLocked()
	return player:GetAttribute("UILocked") or player:GetAttribute("UILockedServer")
end

-- ===== World-space power bar =====
local function getHRP()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function ensureWorldBar()
	local hrp = getHRP()
	if not hrp then return nil end
	local bb = hrp:FindFirstChild("MagnetPowerBillboard")
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = "MagnetPowerBillboard"
		bb.Adornee = hrp
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.MaxDistance = 200
		bb.Size = UDim2.fromOffset(14, 230)           -- thin + long
		bb.StudsOffsetWorldSpace = Vector3.new(3, 0.0, 0) -- ↓ lowered to align with body
		bb.Enabled = false
		bb.Parent = hrp

		local container = Instance.new("Frame")
		container.Name = "Container"
		container.Size = UDim2.fromScale(1,1)
		container.BackgroundColor3 = Color3.fromRGB(0,0,0)
		container.BackgroundTransparency = 0.35
		container.BorderSizePixel = 2
		container.BorderColor3 = Color3.fromRGB(0,0,0)
		container.Parent = bb

		-- White fill: anchored to bottom
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.AnchorPoint = Vector2.new(0,1)
		fill.Position = UDim2.fromScale(0,1)
		fill.Size = UDim2.fromScale(1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(255,255,255)
		fill.BorderSizePixel = 0
		fill.Parent = container

		-- Yellow gradient sweet cap at top
		local sweet = Instance.new("Frame")
		sweet.Name = "Sweet"
		sweet.AnchorPoint = Vector2.new(0,0)
		sweet.Position = UDim2.fromScale(0,0)
		sweet.Size = UDim2.new(1, 0, 0.16, 0)
		sweet.BackgroundColor3 = Color3.fromRGB(255, 225, 70)
		sweet.BorderSizePixel = 0
		sweet.Parent = container

		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = ColorSequence.new(Color3.fromRGB(255,225,70), Color3.fromRGB(0,0,0))
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 0.0),
			NumberSequenceKeypoint.new(1.0, 1.0),
		})
		grad.Parent = sweet
	end
	return bb
end

local function setBarVisible(v)
	local hrp = getHRP(); if not hrp then return end
	local bb = ensureWorldBar(); if not bb then return end
	bb.Enabled = v and true or false
end

local function setBarValue(val01)
	val01 = math.clamp(val01 or 0, 0, 1)
	local hrp = getHRP(); if not hrp then return end
	local bb = hrp:FindFirstChild("MagnetPowerBillboard"); if not bb then return end
	local cont = bb:FindFirstChild("Container"); if not cont then return end
	local fill = cont:FindFirstChild("Fill"); if not fill then return end
	fill.Size = UDim2.fromScale(1, val01)
end

-- ===== Throw logic =====
local HOLD_THRESHOLD = 0.25
local MIN_DIST, MAX_DIST = 10, 20

local preCharging = false
local charging = false
local holdStart = 0
local chargeValue = 0
local dirUp = true
local chargeConn
local lastThrown = false
local currentSpeed = 1.1 -- will randomize 0.5..2.0 per attempt

local rng = Random.new(os.clock())

local function aimTargetByFacing(power01)
	local hrp = getHRP(); if not hrp then return nil end
	local cam = Workspace.CurrentCamera
	local look = cam and cam.CFrame.LookVector or hrp.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 1e-3 then look = hrp.CFrame.LookVector end
	look = look.Unit
	local origin = hrp.Position + Vector3.new(0, 2.5, 0)
	local targetDist = MIN_DIST + (MAX_DIST - MIN_DIST) * math.clamp(power01 or 0, 0, 1)
	return origin + look * targetDist
end

local function startMeter()
	if charging then return end
	charging = true
	chargeValue = 0
	dirUp = true
	currentSpeed = rng:NextNumber(0.5, 2.0) -- randomize speed each time
	ensureWorldBar()
	setBarValue(0)
	setBarVisible(true)

	chargeConn = RunService.RenderStepped:Connect(function(dt)
		local dv = currentSpeed * dt
		if dirUp then
			chargeValue += dv
			if chargeValue >= 1 then chargeValue = 1; dirUp = false end
		else
			chargeValue -= dv
			if chargeValue <= 0 then chargeValue = 0; dirUp = true end
		end
		setBarValue(chargeValue)
	end)
end

local function stopMeter()
	if chargeConn then chargeConn:Disconnect() end
	chargeConn = nil
	charging = false
	preCharging = false
	setBarVisible(false)
end

local function beginHold()
	if uiLocked() then return end
	if not tool.Parent or tool.Parent ~= player.Character then return end
	if lastThrown then
		RequestReelIn:FireServer()
		lastThrown = false
		return
	end
	preCharging = true
	holdStart = time()
	task.spawn(function()
		local started = false
		while preCharging do
			if uiLocked() then preCharging = false break end
			if time() - holdStart >= HOLD_THRESHOLD then
				started = true
				startMeter()
				break
			end
			RunService.Heartbeat:Wait()
		end
		if not started then stopMeter() end
	end)
end

local function throwNow()
	local targetPos = aimTargetByFacing(chargeValue)
	if not targetPos then return end
	lastThrown = true
	CastMagnet:FireServer(targetPos, chargeValue)
end

local function endHold()
	if preCharging and not charging then
		preCharging = false
		stopMeter()
		return
	end
	if charging then
		stopMeter()
		throwNow()
	end
end

-- Inputd
tool.Activated:Connect(beginHold)
tool.Deactivated:Connect(endHold)
UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.R and lastThrown and not uiLocked() then
		RequestReelIn:FireServer()
		lastThrown = false
	end
end)

ReelEnded.OnClientEvent:Connect(function() lastThrown = false; stopMeter() end)
OpenReel.OnClientEvent:Connect(function() stopMeter() end)

tool.AncestryChanged:Connect(function(_, parent)
	if parent == player.Backpack then
		task.defer(function()
			local char = player.Character
			if char and not char:FindFirstChildOfClass("Tool") then tool.Parent = char end
		end)
	end
end)
player.CharacterAdded:Connect(function()
	RunService.Heartbeat:Wait()
	ensureWorldBar()
end)
