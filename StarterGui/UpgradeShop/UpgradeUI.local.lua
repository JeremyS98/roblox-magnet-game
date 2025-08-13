-- UpgradeUI.local.lua (under StarterGui/UpgradeShop)
-- Opens via booth prompt. Has an X close button and auto-closes when you walk away.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local OpenShopRE   = RS:WaitForChild("OpenShop")
local BuyUpgradeRE = RS:WaitForChild("BuyUpgrade")

local gui = script.Parent
gui.ResetOnSpawn = false
gui.Enabled = false

-- Panel
local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.fromScale(0.42, 0.38)
frame.Position = UDim2.fromScale(0.29, 0.31)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BackgroundTransparency = 0.1
frame.Visible = false
frame.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,10); corner.Parent = frame
local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Parent = frame

-- Close X
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.AnchorPoint = Vector2.new(1,0)
closeBtn.Size = UDim2.fromScale(0.1, 0.18)
closeBtn.Position = UDim2.fromScale(0.98, 0.02)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
closeBtn.Text = "X"
closeBtn.TextScaled = true
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Parent = frame
local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0,8); cCorner.Parent = closeBtn
local cStroke = Instance.new("UIStroke"); cStroke.Thickness = 1.5; cStroke.Parent = closeBtn

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(0.8, 0.18)
title.Position = UDim2.fromScale(0.02, 0.02)
title.BackgroundTransparency = 1
title.Text = "🧲 Magnet Upgrades"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromScale(1, 0.12)
coinsLabel.Position = UDim2.fromScale(0, 0.18)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextScaled = true
coinsLabel.TextColor3 = Color3.fromRGB(200,255,200)
coinsLabel.Parent = frame

local function makeRow(yOffset, name, desc)
	local row = Instance.new("Frame")
	row.Size = UDim2.fromScale(1, 0.18)
	row.Position = UDim2.fromScale(0, yOffset)
	row.BackgroundTransparency = 1
	row.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.6, 1)
	label.Position = UDim2.fromScale(0.04, 0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.Text = name .. " — " .. desc
	label.Parent = row

	local buy = Instance.new("TextButton")
	buy.Size = UDim2.fromScale(0.3, 0.9)
	buy.Position = UDim2.fromScale(0.66, 0.05)
	buy.BackgroundColor3 = Color3.fromRGB(40,120,200)
	buy.TextScaled = true
	buy.TextColor3 = Color3.fromRGB(255,255,255)
	buy.Text = "Buy"
	buy.Parent = row

	local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0,8); c1.Parent = buy
	local s1 = Instance.new("UIStroke"); s1.Thickness = 1.5; s1.Parent = buy

	return row, buy, label
end

local rowLuck, btnLuck, lblLuck   = makeRow(0.32, "Luck", "better rarity odds")
local rowReel, btnReel, lblReel   = makeRow(0.52, "Reel Speed", "shorter wait time")
local rowStr , btnStr , lblStr    = makeRow(0.72, "Magnet Strength", "+% sell value")


local note = Instance.new("TextLabel")
note.Size = UDim2.fromScale(1, 0.12)
note.Position = UDim2.fromScale(0, 0.88)
note.BackgroundTransparency = 1
note.TextScaled = true
note.TextColor3 = Color3.fromRGB(200,200,200)
note.Text = "Move away or press X to close."
note.Parent = frame

local state = {
	coins = 0, Luck = 0, Reel = 0, Strength = 0,
	costLuck = "?", costReel = "?", costStrength = "?", max = 10
}

local function refresh()
	gui.Enabled = true
	frame.Visible = true
	coinsLabel.Text = ("Coins: %s"):format(state.coins)

	lblLuck.Text = ("Luck (Lv %d/%d) — %s"):format(state.Luck, state.max, state.costLuck == "MAX" and "MAX" or ("Cost "..state.costLuck))
	btnLuck.Text = (state.costLuck == "MAX") and "MAX" or "Buy"
	btnLuck.AutoButtonColor = (state.costLuck ~= "MAX")

	lblReel.Text = ("Reel Speed (Lv %d/%d) — %s"):format(state.Reel, state.max, state.costReel == "MAX" and "MAX" or ("Cost "..state.costReel))
	btnReel.Text = (state.costReel == "MAX") and "MAX" or "Buy"
	btnReel.AutoButtonColor = (state.costReel ~= "MAX")

	lblStr.Text = ("Magnet Strength (Lv %d/%d) — %s"):format(state.Strength, state.max, state.costStrength == "MAX" and "MAX" or ("Cost "..state.costStrength))
	btnStr.Text = (state.costStrength == "MAX") and "MAX" or "Buy"
	btnStr.AutoButtonColor = (state.costStrength ~= "MAX")
end

btnLuck.MouseButton1Click:Connect(function()
	if state.costLuck ~= "MAX" then BuyUpgradeRE:FireServer("Luck") end
end)
btnReel.MouseButton1Click:Connect(function()
	if state.costReel ~= "MAX" then BuyUpgradeRE:FireServer("Reel") end
end)
btnStr.MouseButton1Click:Connect(function()
	if state.costStrength ~= "MAX" then BuyUpgradeRE:FireServer("Strength") end
end)

OpenShopRE.OnClientEvent:Connect(function(payload)
	if payload and payload.error then
		local m = Instance.new("Message", workspace)
		m.Text = payload.error
		task.delay(1.2, function() m:Destroy() end)
		return
	end
	if payload and payload.ok then
		if payload.which == "Luck" then
			state.Luck = payload.level
			state.costLuck = payload.nextCost
		elseif payload.which == "Reel" then
			state.Reel = payload.level
			state.costReel = payload.nextCost
		elseif payload.which == "Strength" then
			state.Strength = payload.level
			state.costStrength = payload.nextCost
		end
		state.coins = payload.coins or state.coins
		refresh()
		return
	end
	if payload then
		for k,v in pairs(payload) do state[k] = v end
		refresh()
	end
end)

local function closeShop()
	frame.Visible = false
	gui.Enabled = false
end
closeBtn.MouseButton1Click:Connect(closeShop)

-- Auto-close if you walk away from any UpgradeBooth
local watching = false
RunService.RenderStepped:Connect(function()
	if not frame.Visible then return end
	if watching then return end
	watching = true
	task.spawn(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart", 2)
		local limit = 17 -- studs
		local nearest = math.huge
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst.Name == "UpgradeBooth" and (inst:IsA("BasePart") or inst:IsA("Model")) then
				local pos = inst:IsA("Model") and inst:GetPivot().Position or inst.Position
				if hrp and pos then
					local d = (hrp.Position - pos).Magnitude
					if d < nearest then nearest = d end
				end
			end
		end
		if nearest > limit then closeShop() end
		watching = false
	end)
end)
