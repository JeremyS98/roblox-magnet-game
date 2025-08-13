-- MagnetsUI.local.lua
-- ScreenGui-based Magnets UI (place this as a LocalScript inside StarterGui/MagnetsUI)
-- Matches Backpack/Journal style: circular black button + blue "M" badge.
-- Keybind: M. Positioned to the LEFT of Journal/Backpack cluster.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- UIBus (to mutually close UIs like Backpack/Journal)
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end

-- Optional feature flags (safe if missing)
local FF = RS:FindFirstChild("FeatureFlags")

-- Remotes for magnets
local GetMagnetsRF = RS:FindFirstChild("GetMagnets")
local EquipMagnetRF = RS:FindFirstChild("EquipMagnet")

-- Root ScreenGui
local gui = script.Parent
if gui and gui:IsA("ScreenGui") then
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
end

---------------------------------------------------------------------
-- Floating action button (bottom-right cluster, left of Journal/Bag)
---------------------------------------------------------------------
local function makeFab(parent: Instance)
	-- container
	local fab = parent:FindFirstChild("MagnetsFAB")
	if fab then fab:Destroy() end

	fab = Instance.new("Frame")
	fab.Name = "MagnetsFAB"
	fab.AnchorPoint = Vector2.new(1,1)
	-- Place to the LEFT of the existing bottom-right buttons (journal/backpack)
	-- Backpack & Journal sit around X=0.94..0.98; use 0.86 to avoid overlap.
	fab.Position = UDim2.fromScale(0.86, 0.95)
	fab.Size = UDim2.fromOffset(64, 64)
	fab.BackgroundTransparency = 1
	fab.Parent = parent
	fab.ZIndex = 50

	-- circular button
	local btn = Instance.new("ImageButton")
	btn.Name = "Button"
	btn.AnchorPoint = Vector2.new(0.5,0.5)
	btn.Position = UDim2.fromScale(0.5, 0.5)
	btn.Size = UDim2.fromOffset(64,64)
	btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
	btn.AutoButtonColor = true
	btn.Parent = fab
	btn.ZIndex = 51

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(10,10,10)
	stroke.Parent = btn

	-- magnet icon (emoji fallback)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1,1)
	icon.Text = "🧲"
	icon.TextScaled = true
	icon.TextColor3 = Color3.fromRGB(230,230,230)
	icon.Font = Enum.Font.GothamBold
	icon.Parent = btn
	icon.ZIndex = 52

	-- blue badge with "M"
	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(1,0)
	badge.Position = UDim2.fromScale(1.02, -0.06) -- top-right
	badge.Size = UDim2.fromOffset(26,26)
	badge.BackgroundColor3 = Color3.fromRGB(80,140,255)
	badge.Text = "M"
	badge.TextScaled = true
	badge.TextColor3 = Color3.new(1,1,1)
	badge.Font = Enum.Font.GothamBold
	badge.Parent = btn
	badge.ZIndex = 53
	local bcorner = Instance.new("UICorner")
	bcorner.CornerRadius = UDim.new(1,0)
	bcorner.Parent = badge
	local bstroke = Instance.new("UIStroke")
	bstroke.Thickness = 1.5
	bstroke.Color = Color3.fromRGB(35,85,200)
	bstroke.Parent = badge

	return btn
end

---------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------
local function makePanel(parent: Instance)
	local panel = parent:FindFirstChild("MagnetsPanel")
	if panel then panel:Destroy() end

	panel = Instance.new("Frame")
	panel.Name = "MagnetsPanel"
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	panel.Position = UDim2.fromScale(0.5, 0.52)
	panel.Size = UDim2.fromScale(0.46, 0.46)
	panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = parent
	panel.ZIndex = 60

	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,12); corner.Parent = panel
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Parent = panel

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.16)
	header.Parent = panel
	header.ZIndex = 61

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.7, 1)
	title.Position = UDim2.fromScale(0.04, 0)
	title.Text = "🧲  Magnets" -- no (disable) text here
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.Parent = header
	title.ZIndex = 61

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(1,0.5)
	closeBtn.Position = UDim2.fromScale(0.97, 0.5)
	closeBtn.Size = UDim2.fromOffset(32,32)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	closeBtn.Text = "X"
	closeBtn.TextScaled = true
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Parent = header
	closeBtn.ZIndex = 61
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,8); cc.Parent = closeBtn

	-- Grid area
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1, 0.84)
	body.Position = UDim2.fromScale(0, 0.16)
	body.Parent = panel
	body.ZIndex = 60

	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(0.92, 0.88)
	grid.Position = UDim2.fromScale(0.04, 0.06)
	grid.Parent = body
	grid.ZIndex = 60

	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.CellSize = UDim2.fromScale(0.23, 0.30)
	layout.FillDirectionMaxCells = 4
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local empty = Instance.new("TextLabel")
	empty.Name = "Empty"
	empty.BackgroundTransparency = 1
	empty.Size = UDim2.fromScale(1, 1)
	empty.Text = "No magnets yet."
	empty.TextScaled = true
	empty.TextColor3 = Color3.fromRGB(230,230,230)
	empty.Font = Enum.Font.GothamBlack
	empty.Parent = body
	empty.ZIndex = 60

	-- Behavior
	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
		player:SetAttribute("UILocked", false)
		UIBus:Fire("Magnets") -- inform others
	end)

	return panel
end

---------------------------------------------------------------------
-- Populate catalog (read-only for now)
---------------------------------------------------------------------
local function addCard(grid: Instance, def: table, equippedId: string, repopulateCb: ()->())
	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.fromRGB(28,28,32)
	card.ZIndex = 61

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = card
	local s = Instance.new("UIStroke"); s.Thickness = 1.2; s.Parent = card

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.92, 0.32)
	name.Position = UDim2.fromScale(0.04, 0.06)
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Color3.fromRGB(240,240,240)
	name.Font = Enum.Font.GothamBold
	name.Text = tostring(def.name or def.id or "Magnet")
	name.Parent = card
	name.ZIndex = 62

	local stats = Instance.new("TextLabel")
	stats.BackgroundTransparency = 1
	stats.Size = UDim2.fromScale(0.92, 0.34)
	stats.Position = UDim2.fromScale(0.04, 0.40)
	stats.TextScaled = true
	stats.TextXAlignment = Enum.TextXAlignment.Left
	stats.TextYAlignment = Enum.TextYAlignment.Top
	stats.TextColor3 = Color3.fromRGB(210,210,210)
	stats.Font = Enum.Font.Gotham
	stats.TextWrapped = true
	local st = def.stats or {}
	stats.Text = string.format("Lure %.1f  Rarity %.1f\nControl %.1f  Weight %.1f  Stability %.1f",
		(st.lure or 1), (st.rarity or 1), (st.control or 1), (st.weight or 1), (st.stability or 1))
	stats.Parent = card
	stats.ZIndex = 62

	local equip = Instance.new("TextButton")
	equip.Name = "Equip"
	equip.AnchorPoint = Vector2.new(1,1)
	equip.Position = UDim2.fromScale(0.96, 0.94)
	equip.Size = UDim2.fromScale(0.46, 0.28)
	equip.BackgroundColor3 = Color3.fromRGB(80,140,255)
	equip.TextColor3 = Color3.new(1,1,1)
	equip.TextScaled = true
	equip.Font = Enum.Font.GothamBold
	equip.Text = (def.id == equippedId) and "Equipped" or "Equip"
	equip.Parent = card
	equip.ZIndex = 62
	local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0,6); ec.Parent = equip

	equip.MouseButton1Click:Connect(function()
		if not EquipMagnetRF then return end
		local ok, res = pcall(function()
			return EquipMagnetRF:InvokeServer(def.id)
		end)
		if ok and res and res.ok then
			repopulateCb()
		end
	end)

	card.Parent = grid
end

---------------------------------------------------------------------
-- Open/close & data fetch
---------------------------------------------------------------------
local function buildOnce()
	if gui:FindFirstChild("MagnetsPanel") then return end
	makePanel(gui)
end

local function populate()
	local panel = gui:FindFirstChild("MagnetsPanel")
	if not panel then return end
	local grid = panel.Body.Grid
	for _,ch in ipairs(grid:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
	local empty = panel.Body.Empty

	local catalog, equippedId = nil, nil

	if GetMagnetsRF then
		local ok, res = pcall(function() return GetMagnetsRF:InvokeServer() end)
		if ok and type(res) == "table" then
			catalog = res.catalog
			equippedId = res.equipped
		end
	end

	if type(catalog) ~= "table" or #catalog == 0 then
		empty.Visible = true
	else
		empty.Visible = false
		for _,def in ipairs(catalog) do
			addCard(grid, def, equippedId, populate)
		end
	end
end

local function open()
	UIBus:Fire("Magnets")
	buildOnce()
	populate()
	local panel = gui:FindFirstChild("MagnetsPanel")
	if panel then
		panel.Visible = true
		player:SetAttribute("UILocked", true)
	end
end

local function close()
	local panel = gui:FindFirstChild("MagnetsPanel")
	if panel then
		panel.Visible = false
		player:SetAttribute("UILocked", false)
	end
end

-- Create the fab and wire controls
local fabBtn = makeFab(gui)
fabBtn.MouseButton1Click:Connect(function()
	local panel = gui:FindFirstChild("MagnetsPanel")
	if panel and panel.Visible then close() else open() end
end)

-- Keybind M
UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.M then
		local panel = gui:FindFirstChild("MagnetsPanel")
		if panel and panel.Visible then close() else open() end
	end
end)

-- Close if another UI opens via UIBus
UIBus.Event:Connect(function(who)
	if who ~= "Magnets" then close() end
end)
