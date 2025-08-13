-- MagnetsUI.local.lua
-- Bottom-left circular "M" button (like Backpack/Journal) + panel to view/equip magnets.
-- Safe: creates its own ScreenGui under PlayerGui; no ResetOnSpawn on PlayerScripts.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UIBus for mutual exclusion with other panels (Backpack/Journal, etc.)
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end

-- Remotes
local GetMagnetsRF = RS:WaitForChild("GetMagnets", 5)
local EquipMagnetRF = RS:WaitForChild("EquipMagnet", 5)

-- Build ScreenGui
local gui = playerGui:FindFirstChild("MagnetsUI")
if not gui then
	gui = Instance.new("ScreenGui")
	gui.Name = "MagnetsUI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
end

-- Floating badge button (bottom-left), styled like your other circular badges.
local function ensureBadge()
	local badge = gui:FindFirstChild("MagnetsBadge")
	if badge then return badge end
	badge = Instance.new("TextButton")
	badge.Name = "MagnetsBadge"
	badge.Size = UDim2.fromOffset(56, 56)
	badge.Position = UDim2.fromScale(0.065, 0.92) -- bottom-left cluster
	badge.AnchorPoint = Vector2.new(0,1)
	badge.BackgroundColor3 = Color3.fromRGB(41, 128, 185) -- blue circle
	badge.Text = "M"
	badge.TextScaled = true
	badge.TextColor3 = Color3.fromRGB(255,255,255)
	badge.AutoButtonColor = true
	badge.Parent = gui

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1,0)
	c.Parent = badge

	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.fromRGB(20, 60, 100)
	s.Parent = badge
	return badge
end

-- Panel
local function ensurePanel()
	local panel = gui:FindFirstChild("Panel")
	if panel then return panel end

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(0.44, 0.54)
	panel.Position = UDim2.fromScale(0.28, 0.24)
	panel.BackgroundColor3 = Color3.fromRGB(18,18,22)
	panel.Visible = false
	panel.Parent = gui

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Color = Color3.fromRGB(60,60,70); s.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.6, 0.12)
	title.Position = UDim2.fromScale(0.04, 0.03)
	title.Text = "🧲 Magnets"
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(235,235,240)
	title.Parent = panel

	-- "(disabled)" note (when Magnet system off) – placed under the X, not hidden
	local note = Instance.new("TextLabel")
	note.Name = "DisabledHint"
	note.BackgroundTransparency = 1
	note.Size = UDim2.fromScale(0.32, 0.10)
	note.Position = UDim2.fromScale(0.64, 0.05)
	note.Text = "(disabled)"
	note.TextScaled = true
	note.TextColor3 = Color3.fromRGB(180, 120, 120)
	note.TextXAlignment = Enum.TextXAlignment.Right
	note.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(1,0)
	closeBtn.Size = UDim2.fromScale(0.08, 0.12)
	closeBtn.Position = UDim2.fromScale(0.98, 0.02)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	closeBtn.Text = "X"
	closeBtn.TextScaled = true
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Parent = panel
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,8); cc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
		UIBus:Fire("Magnets")
	end)

	-- Scroll list
	local listFrame = Instance.new("Frame")
	listFrame.Name = "List"
	listFrame.BackgroundTransparency = 1
	listFrame.Size = UDim2.fromScale(0.94, 0.78)
	listFrame.Position = UDim2.fromScale(0.03, 0.18)
	listFrame.Parent = panel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.fromScale(1,1)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.ScrollBarThickness = 6
	scroll.Parent = listFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	local function recalcCanvas()
		task.defer(function()
			local y = 0
			for _,child in ipairs(scroll:GetChildren()) do
				if child:IsA("Frame") then
					y += child.AbsoluteSize.Y + layout.Padding.Offset
				end
			end
			scroll.CanvasSize = UDim2.new(0,0,0,y+8)
		end)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(recalcCanvas)

	-- Flag mirror: hide "(disabled)" if MagnetsEnabled is true
	local flagsFolder = RS:FindFirstChild("FeatureFlags")
	if flagsFolder then
		local flag = flagsFolder:FindFirstChild("MagnetsEnabled")
		if flag and flag:IsA("BoolValue") then
			note.Visible = not flag.Value
			flag.Changed:Connect(function(v) note.Visible = not v end)
		else
			note.Visible = true
		end
	else
		note.Visible = true
	end

	return panel
end

local badge = ensureBadge()
local panel = ensurePanel()

-- Close when other panels request it
UIBus.Event:Connect(function(who)
	if who ~= "Magnets" and panel.Visible then
		panel.Visible = false
	end
end)

local function buildRow(parent, entry, equippedId)
	local row = Instance.new("Frame")
	row.Name = "Row_"..tostring(entry.id or entry.name or "item")
	row.Size = UDim2.fromScale(1, 0.16)
	row.BackgroundColor3 = Color3.fromRGB(26,26,30)
	row.Parent = parent

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = row
	local s = Instance.new("UIStroke"); s.Thickness = 1; s.Color = Color3.fromRGB(70,70,80); s.Parent = row

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.66, 1)
	name.Position = UDim2.fromScale(0.03, 0)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextScaled = true
	name.TextColor3 = Color3.fromRGB(235,235,240)
	name.Text = string.format("%s", tostring(entry.name or entry.id or "Magnet"))
	name.Parent = row

	local equip = Instance.new("TextButton")
	equip.Name = "Equip"
	equip.AnchorPoint = Vector2.new(1,0.5)
	equip.Position = UDim2.fromScale(0.96, 0.5)
	equip.Size = UDim2.fromScale(0.20, 0.70)
	equip.BackgroundColor3 = Color3.fromRGB(60,120,80)
	equip.TextScaled = true
	equip.TextColor3 = Color3.new(1,1,1)
	equip.Text = (entry.id == equippedId) and "Equipped" or "Equip"
	equip.AutoButtonColor = true
	equip.Parent = row
	local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0,8); ec.Parent = equip

	equip.MouseButton1Click:Connect(function()
		if EquipMagnetRF then
			local ok, res = pcall(function()
				return EquipMagnetRF:InvokeServer(entry.id)
			end)
			if ok and type(res)=="table" and res.ok then
				equip.Text = "Equipped"
			end
		end
	end)

	return row
end

local function populate()
	local scroll = panel.List.Scroll
	for _,child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- Fetch catalog
	local equippedId, catalog = nil, {}
	if GetMagnetsRF then
		local ok, res = pcall(function() return GetMagnetsRF:InvokeServer() end)
		if ok and type(res)=="table" then
			equippedId = res.equipped
			catalog = res.catalog or {}
		end
	end

	if #catalog == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.fromScale(1,1)
		empty.Text = "No magnets yet."
		empty.TextScaled = true
		empty.TextColor3 = Color3.fromRGB(200,200,205)
		empty.Parent = panel.List.Scroll
		return
	end

	for _,entry in ipairs(catalog) do
		buildRow(panel.List.Scroll, entry, equippedId)
	end
end

local function open()
	UIBus:Fire("Magnets")
	panel.Visible = true
	populate()
end
local function close()
	panel.Visible = false
end

badge.MouseButton1Click:Connect(function()
	if panel.Visible then close() else open() end
end)

-- Keybind: M
UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.M then
		if panel.Visible then close() else open() end
	end
end)
