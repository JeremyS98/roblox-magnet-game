-- StarterPlayer/StarterPlayerScripts/ServerBoostHUD.local.lua
-- Shows a small top-center chip: "Luck xN – mm:ss" while server luck is active.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Feature flag gate (optional safety)
local flagsFolder = ReplicatedStorage:WaitForChild("FeatureFlags", 5)
local serverLuckUIFlag = flagsFolder and flagsFolder:FindFirstChild("ServerLuckUI")

local function ffEnabled()
	if not serverLuckUIFlag then return true end -- default on if missing
	return serverLuckUIFlag.Value == true
end

-- RemoteEvent the server fires whenever server luck changes
local BoostChanged = ReplicatedStorage:WaitForChild("BoostChanged", 5)

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "BoostHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Chip"
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0.02, 0)
frame.Size = UDim2.new(0, 220, 0, 28)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = frame

local label = Instance.new("TextLabel")
label.Name = "Text"
label.BackgroundTransparency = 1
label.Size = UDim2.new(1, 0, 1, 0)
label.Font = Enum.Font.GothamSemibold
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(240, 240, 240)
label.Text = ""
label.Parent = frame

local running = false
local mult = 1.0
local expireAt = 0

local function fmtRemaining(sec)
	sec = math.max(0, math.floor(sec + 0.5))
	local m = math.floor(sec / 60)
	local s = sec % 60
	return string.format("%d:%02d", m, s)
end

local function updateText()
	label.Text = string.format("Luck x%s – %s", tostring(mult), fmtRemaining(expireAt - os.time()))
end

local function stopChip()
	running = false
	frame.Visible = false
end

local function startChip()
	if not ffEnabled() then return end
	if running then return end
	running = true
	frame.Visible = true
	task.spawn(function()
		while running do
			updateText()
			if os.time() >= expireAt then
				stopChip()
				break
			end
			task.wait(0.25)
		end
	end)
end

-- Accept either a table or separate args from the server for robustness.
local function onBoostChanged(payloadA, payloadB, payloadC)
	-- Supported server shapes:
	-- 1) BoostChanged:FireAllClients({type="server_luck", mult=2.0, remaining=900})
	-- 2) BoostChanged:FireAllClients("server_luck", 2.0, os.time()+900)
	-- 3) BoostChanged:FireClient(plr, 2.0, remainingSeconds)
	
	if typeof(payloadA) == "table" then
		if payloadA.type == "server_luck" or payloadA.mult then
			mult = tonumber(payloadA.mult or 1) or 1
			local remaining = tonumber(payloadA.remaining or 0) or 0
			expireAt = os.time() + math.max(0, remaining)
		else
			-- Unknown table; ignore
			return
		end
	else
		-- Non-table: interpret as variant (type, mult, expiryOrRemaining) or (mult, remaining)
		if typeof(payloadA) == "string" then
			-- assume first is type string
			mult = tonumber(payloadB or 1) or 1
			local val = tonumber(payloadC or 0) or 0
			-- If value looks like a timestamp far in the future, treat as absolute; else remaining seconds
			if val > os.time() then
				expireAt = val
			else
				expireAt = os.time() + math.max(0, val)
			end
		else
			-- assume (mult, remaining)
			mult = tonumber(payloadA or 1) or 1
			local remaining = tonumber(payloadB or 0) or 0
			expireAt = os.time() + math.max(0, remaining)
		end
	end

	if mult <= 1 or expireAt <= os.time() then
		stopChip()
		return
	end

	startChip()
end

if BoostChanged then
	BoostChanged.OnClientEvent:Connect(onBoostChanged)
end

-- Request initial state on spawn if a bridge RF exists
local getStateRF = ReplicatedStorage:FindFirstChild("GetServerLuckState")
if getStateRF and getStateRF:IsA("RemoteFunction") then
	local ok, data = pcall(function() return getStateRF:InvokeServer() end)
	if ok and data and data.active and data.remaining then
		onBoostChanged({ type = "server_luck", mult = data.mult or 1, remaining = data.remaining })
	end
end
