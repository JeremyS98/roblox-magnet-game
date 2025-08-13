-- StarterPlayer/StarterPlayerScripts/ServerBoostHUD.local.lua
-- Shows a small top-area chip: "Luck xN – mm:ss" while server luck is active.
-- Positioned at 1/4 of the screen width (from left to right).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local function waitForChildTimeout(parent, name, timeout)
	local obj = parent:FindFirstChild(name)
	if obj then return obj end
	local t0 = os.clock()
	while os.clock() - t0 < (timeout or 5) do
		obj = parent:FindFirstChild(name)
		if obj then return obj end
		task.wait(0.1)
	end
	return nil
end

-- Flags (optional)
local flagsFolder = waitForChildTimeout(ReplicatedStorage, "FeatureFlags", 5)
local serverLuckUIFlag = flagsFolder and flagsFolder:FindFirstChild("ServerLuckUI")
local function ffEnabled()
	if not serverLuckUIFlag then return true end
	return serverLuckUIFlag.Value == true
end
if serverLuckUIFlag then
	serverLuckUIFlag:GetPropertyChangedSignal("Value"):Connect(function()
		-- hide if turned off while running
		if not ffEnabled() then
			local hud = player.PlayerGui:FindFirstChild("BoostHUD")
			if hud then hud.Enabled = false end
		end
	end)
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "BoostHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Chip"
frame.AnchorPoint = Vector2.new(0.5, 0)
-- Moved from top-center (0.5, 0.02) to quarter screen (0.25, 0.02)
frame.Position = UDim2.new(0.25, 0, 0.02, 0)
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
			task.wait(0.2)
		end
	end)
end

-- Attach to BoostChanged (retry if event is created late)
local BoostChanged
task.spawn(function()
	for i = 1, 50 do -- try for ~5s total
		BoostChanged = ReplicatedStorage:FindFirstChild("BoostChanged")
		if BoostChanged and BoostChanged:IsA("RemoteEvent") then break end
		task.wait(0.1)
	end
	if BoostChanged then
		BoostChanged.OnClientEvent:Connect(function(payloadA, payloadB, payloadC)
			if typeof(payloadA) == "table" then
				if payloadA.type == "server_luck" or payloadA.mult then
					mult = tonumber(payloadA.mult or 1) or 1
					local remaining = tonumber(payloadA.remaining or 0) or 0
					expireAt = os.time() + math.max(0, remaining)
				else
					return
				end
			else
				if typeof(payloadA) == "string" then
					mult = tonumber(payloadB or 1) or 1
					local val = tonumber(payloadC or 0) or 0
					if val > os.time() then
						expireAt = val
					else
						expireAt = os.time() + math.max(0, val)
					end
				else
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
		end)
	end
end)

-- Fetch initial state after spawn
task.spawn(function()
	local rf
	for i = 1, 50 do
		rf = ReplicatedStorage:FindFirstChild("GetServerLuckState")
		if rf and rf:IsA("RemoteFunction") then break end
		task.wait(0.1)
	end
	if rf then
		local ok, data = pcall(function() return rf:InvokeServer() end)
		if ok and data and data.active and data.remaining then
			mult = tonumber(data.mult or 1) or 1
			expireAt = os.time() + math.max(0, tonumber(data.remaining or 0) or 0)
			startChip()
		end
	end
end)
