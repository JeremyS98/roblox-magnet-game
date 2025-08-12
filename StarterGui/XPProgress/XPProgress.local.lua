-- XPProgress.local.lua
-- Shows a slim progress bar toast whenever XP is gained. Displays:
--  "Level: N"  (title)
--  progress fill (current/need)
--  "+X XP" under the bar

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local XPUpdateRE = RS:WaitForChild("XPUpdate")

local gui = script.Parent
gui.ResetOnSpawn = false
gui.Enabled = true

-- Container
local panel = Instance.new("Frame")
panel.Name = "XPToast"
panel.Size = UDim2.fromScale(0.36, 0.14)
panel.Position = UDim2.fromScale(0.32, 0.03)
panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
panel.BackgroundTransparency = 0.15
panel.Visible = false
panel.ZIndex = 80
panel.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,10); corner.Parent = panel
local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Parent = panel

-- Title "Level: X"
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.fromScale(1, 0.35)
title.Position = UDim2.fromScale(0, 0.05)
title.Text = "Level: 1"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Parent = panel

-- Bar bg
local barBG = Instance.new("Frame")
barBG.Size = UDim2.fromScale(0.92, 0.28)
barBG.Position = UDim2.fromScale(0.04, 0.45)
barBG.BackgroundColor3 = Color3.fromRGB(32,32,36)
barBG.Parent = panel
local bgc = Instance.new("UICorner"); bgc.CornerRadius = UDim.new(0,8); bgc.Parent = barBG

-- Fill
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
barFill.Parent = barBG
local fgc = Instance.new("UICorner"); fgc.CornerRadius = UDim.new(0,8); fgc.Parent = barFill

-- +X XP
local deltaLabel = Instance.new("TextLabel")
deltaLabel.BackgroundTransparency = 1
deltaLabel.Size = UDim2.fromScale(1, 0.2)
deltaLabel.Position = UDim2.fromScale(0, 0.78)
deltaLabel.Text = "+0 XP"
deltaLabel.TextScaled = true
deltaLabel.TextColor3 = Color3.fromRGB(180,220,255)
deltaLabel.Parent = panel

local function animateShow()
	panel.Visible = true
	panel.BackgroundTransparency = 0.15
	title.TextTransparency = 0
	deltaLabel.TextTransparency = 0
end

local function animateHide()
	for i=0,1,0.08 do
		panel.BackgroundTransparency = 0.15 + i*0.85
		title.TextTransparency = i
		deltaLabel.TextTransparency = i
		barFill.BackgroundTransparency = i
		task.wait(0.03)
	end
	panel.Visible = false
end

local function setProgress(xp, need)
	local t = 0
	if need > 0 then t = math.clamp(xp / need, 0, 1) end
	barFill:TweenSize(UDim2.fromScale(t, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
end

-- Drive from server
local hideDebounce = 0
XPUpdateRE.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	local level = tonumber(payload.level) or 1
	local xp    = tonumber(payload.xp) or 0
	local need  = tonumber(payload.need) or 1
	local delta = tonumber(payload.delta) or 0

	title.Text = ("Level: %d"):format(level)
	deltaLabel.Text = ("+%d XP"):format(delta)
	setProgress(xp, need)

	animateShow()
	-- Hide after a moment; refresh timer on new events so it sticks while gaining multiple times.
	hideDebounce += 1
	local this = hideDebounce
	task.delay(1.8, function()
		if this == hideDebounce then
			animateHide()
		end
	end)
end)
