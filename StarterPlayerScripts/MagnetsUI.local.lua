-- MagnetsUI.local.lua
-- Minimal, safe UI for equipping magnets from the shadow catalog.
-- Reads FeatureFlags mirror in ReplicatedStorage; if absent or disabled, the
-- UI still opens but will show a small "(disabled)" hint. No gameplay change
-- unless server uses the equipped id.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Remotes / bridges (tolerant to missing objects)
local function waitOrNil(parent, name, t)
	t = t or 5
	local obj = parent:FindFirstChild(name)
	if obj then return obj end
	local got = nil
	local started = tick()
	while tick() - started < t do
		got = parent:FindFirstChild(name)
		if got then return got end
		task.wait(0.1)
	end
	return nil
end

local FeatureFlagsFolder = waitOrNil(RS, "FeatureFlags", 2)
local ReelV2Flag = FeatureFlagsFolder and FeatureFlagsFolder:FindFirstChild("ReelV2Enabled")
local MagnetsFlag = FeatureFlagsFolder and FeatureFlagsFolder:FindFirstChild("MagnetsEnabled")

local GetMagnetsRF = waitOrNil(RS, "GetMagnets", 2)
local EquipMagnetRF = waitOrNil(RS, "EquipMagnet", 2)

-- UIBus mutual exclusion
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end

-- GUI root
local gui = Instance.new("ScreenGui")
gui.Name = "MagnetsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Top button (left of the existing Shop button)
local topBtn = Instance.new("TextButton")
topBtn.Name = "MagnetsButton"
topBtn.AnchorPoint = Vector2.new(0.5, 0)
topBtn.Size = UDim2.fromOffset(110, 36)
topBtn.Position = UDim2.fromScale(0.42, 0.02) -- quarter-ish across, try to avoid Shop
topBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 40)
topBtn.Text = "🧲 Magnets"
topBtn.TextScaled = true
topBtn.TextColor3 = Color3.new(1,1,1)
topBtn.Parent = gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = topBtn
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Parent = topBtn
end

-- Panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(0.44, 0.54)
panel.Position = UDim2.fromScale(0.28, 0.18)
panel.Visible = false
panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
panel.Parent = gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Parent = panel
end

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.fromScale(0.7, 0.12)
title.Position = UDim2.fromScale(0.03, 0.02)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "🧲 Magnets"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Parent = panel

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.fromScale(0.6, 0.10)
hint.Position = UDim2.fromScale(0.40, 0.03)
hint.TextScaled = true
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.TextColor3 = Color3.fromRGB(200, 200, 200)
hint.Text = (MagnetsFlag and MagnetsFlag.Value == true) and "" or "(disabled)"
hint.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Size = UDim2.fromScale(0.08, 0.12)
closeBtn.Position = UDim2.fromScale(0.98, 0.02)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
closeBtn.Text = "X"
closeBtn.TextScaled = true
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Parent = panel
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = closeBtn
end

local gridHolder = Instance.new("Frame")
gridHolder.Name = "Grid"
gridHolder.BackgroundTransparency = 1
gridHolder.Size = UDim2.fromScale(0.94, 0.78)
gridHolder.Position = UDim2.fromScale(0.03, 0.18)
gridHolder.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.CellSize = UDim2.fromScale(0.31, 0.30)
grid.FillDirectionMaxCells = 3
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = gridHolder

local equippedId : string? = nil
local lastCatalog = {}

local function setOpen(open: boolean)
	panel.Visible = open
	if open then
		UIBus:Fire("Magnets")
	end
end

UIBus.Event:Connect(function(who)
	if who ~= "Magnets" then
		setOpen(false)
	end
end)

local function clearGrid()
	for _,child in ipairs(gridHolder:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function makeRow(entry)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(28,28,32)
	frame.Parent = gridHolder
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = frame
		local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Parent = frame
	end

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.95, 0.28)
	name.Position = UDim2.fromScale(0.03, 0.04)
	name.Text = tostring(entry.id or "?")
	name.TextScaled = true
	name.TextColor3 = Color3.fromRGB(230,230,230)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = frame

	local stats = entry.stats or {}
	local statText = string.format("lure %.1f  rarity %.1f  control %.1f  weight %.1f  stability %.1f",
		tonumber(stats.lure or stats.speed or 1),
		tonumber(stats.rarity or stats.luck or 1),
		tonumber(stats.control or 1),
		tonumber(stats.weight or stats.maxWeight or 1),
		tonumber(stats.stability or 1)
	)

	local statLbl = Instance.new("TextLabel")
	statLbl.BackgroundTransparency = 1
	statLbl.Size = UDim2.fromScale(0.95, 0.34)
	statLbl.Position = UDim2.fromScale(0.03, 0.32)
	statLbl.Text = statText
	statLbl.TextScaled = true
	statLbl.TextColor3 = Color3.fromRGB(200,200,200)
	statLbl.TextXAlignment = Enum.TextXAlignment.Left
	statLbl.Parent = frame

	local equipBtn = Instance.new("TextButton")
	equipBtn.AnchorPoint = Vector2.new(1, 1)
	equipBtn.Size = UDim2.fromScale(0.44, 0.28)
	equipBtn.Position = UDim2.fromScale(0.95, 0.92)
	equipBtn.BackgroundColor3 = Color3.fromRGB(60,120,80)
	equipBtn.Text = (equippedId == entry.id) and "✓ Equipped" or "Equip"
	equipBtn.TextScaled = true
	equipBtn.TextColor3 = Color3.new(1,1,1)
	equipBtn.Parent = frame
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = equipBtn
	end

	equipBtn.MouseButton1Click:Connect(function()
		if not EquipMagnetRF then return end
		local ok, res = pcall(function()
			return EquipMagnetRF:InvokeServer(entry.id)
		end)
		if ok and type(res) == "table" and res.ok == true then
			equippedId = res.equipped
			-- refresh button labels
			for _,child in ipairs(gridHolder:GetChildren()) do
				if child:IsA("Frame") then
					local b = child:FindFirstChildWhichIsA("TextButton")
					if b then
						local lblName = child:FindFirstChildWhichIsA("TextLabel")
						local idHere = lblName and lblName.Text or ""
						b.Text = (idHere == equippedId) and "✓ Equipped" or "Equip"
					end
				end
			end
		end
	end)
end

local function populate()
	if not GetMagnetsRF then return end
	local ok, res = pcall(function()
		return GetMagnetsRF:InvokeServer()
	end)
	if not ok or type(res) ~= "table" then return end
	equippedId = res.equipped
	lastCatalog = res.catalog or {}
	clearGrid()
	for _,entry in ipairs(lastCatalog) do
		makeRow(entry)
	end
	-- update hint if flag toggled while open
	if MagnetsFlag then
		hint.Text = MagnetsFlag.Value and "" or "(disabled)"
	end
end

topBtn.MouseButton1Click:Connect(function()
	if panel.Visible then
		setOpen(false)
	else
		populate()
		setOpen(true)
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	setOpen(false)
end)

-- Keyboard shortcut (M)
UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.M then
		if panel.Visible then
			setOpen(false)
		else
			populate()
			setOpen(true)
		end
	end
end)

-- React to MagnetsEnabled flag changes
if MagnetsFlag then
	MagnetsFlag:GetPropertyChangedSignal("Value"):Connect(function()
		hint.Text = MagnetsFlag.Value and "" or "(disabled)"
	end)
end
