-- ServerLuckHUD.local.lua
-- Displays a small on-screen chip while server luck is active (e.g., "Luck x2 • 01:23").

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Name = "BoostHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local chip = Instance.new("Frame")
chip.Name = "LuckChip"
chip.AnchorPoint = Vector2.new(1, 0) -- top-right
chip.Size = UDim2.fromScale(0.18, 0.06)
chip.Position = UDim2.fromScale(0.985, 0.02)
chip.BackgroundColor3 = Color3.fromRGB(35, 48, 72)
chip.Visible = false
chip.Parent = gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = chip
	local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Parent = chip
end

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1,1)
label.Position = UDim2.fromScale(0,0)
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(220, 240, 255)
label.Font = Enum.Font.GothamBold
label.Parent = chip

-- Helpers
local function fmtTime(s)
	s = math.max(0, math.floor(s or 0))
	local m = math.floor(s/60)
	local r = s % 60
	return string.format("%02d:%02d", m, r)
end

local remaining = 0
local mult = 1.0

local function refreshLabel()
	if mult and mult > 1.0 and remaining > 0 then
		label.Text = string.format("Luck x%s • %s", tostring(mult), fmtTime(remaining))
		chip.Visible = true
	else
		chip.Visible = false
	end
end

-- Seed from server at start
task.spawn(function()
	local GetBoostState = RS:WaitForChild("GetBoostState", 5)
	if GetBoostState then
		local ok, data = pcall(function()
			return GetBoostState:InvokeServer()
		end)
		if ok and typeof(data) == "table" then
			mult = tonumber(data.mult) or 1.0
			remaining = tonumber(data.remaining) or 0
			refreshLabel()
		end
	end
end)

-- React to changes
local BoostChanged = RS:WaitForChild("BoostChanged", 5)
if BoostChanged and BoostChanged.IsA and BoostChanged:IsA("RemoteEvent") then
	BoostChanged.OnClientEvent:Connect(function(kind, state)
		if kind == "ServerLuck" and typeof(state) == "table" then
			mult = tonumber(state.mult) or 1.0
			-- Re-seed remaining from server if available
			local GetBoostState = RS:FindFirstChild("GetBoostState")
			if GetBoostState then
				local ok, data = pcall(function()
					return GetBoostState:InvokeServer()
				end)
				if ok and typeof(data) == "table" then
					remaining = tonumber(data.remaining) or 0
				else
					remaining = 0
				end
			end
			refreshLabel()
		end
	end)
end

-- Countdown
RunService.RenderStepped:Connect(function(dt)
	if chip.Visible and remaining > 0 then
		remaining -= dt
		if remaining < 0 then remaining = 0 end
		refreshLabel()
	end
end)
