-- MagnetsUI.local.lua
-- ScreenGui-based UI (like Backpack/Journal). Adds a circular magnet FAB with blue "M" badge.
-- Toggle key: M. Positioned bottom-right next to other FABs.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes
local GetMagnetsRF = RS:FindFirstChild("GetMagnets")
local EquipMagnetRF = RS:FindFirstChild("EquipMagnet")

-- UIBus (mutual exclusion with other windows)
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end

-- Ensure we run under a ScreenGui
local gui = script.Parent
if not gui or not gui:IsA("ScreenGui") then
	-- if the script is under StarterPlayerScripts by mistake, create our own ScreenGui
	gui = Instance.new("ScreenGui")
	gui.Name = "MagnetsUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = playerGui
end
gui.ResetOnSpawn = false

---------------------------------------------------------------------
-- FAB (round button) bottom-right
---------------------------------------------------------------------
local function makeMagnetFAB()
	local fab = gui:FindFirstChild("MagnetsFAB")
	if fab then return fab end

	fab = Instance.new("Frame")
	fab.Name = "MagnetsFAB"
	fab.AnchorPoint = Vector2.new(1,1)
	-- Place left of the two buttons on the right (journal/backpack): ~0.86 keeps it to the left.
	fab.Position = UDim2.fromScale(0.86, 0.95)
	fab.Size = UDim2.fromOffset(64,64)
	fab.BackgroundColor3 = Color3.fromRGB(28,28,32)
	fab.Parent = gui

	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = fab
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(18,18,20); stroke.Parent = fab

	-- Magnet glyph (emoji) centered
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1,1)
	icon.Position = UDim2.fromScale(0,0)
	icon.Text = "🧲"
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.fromRGB(230,230,230)
	icon.Parent = fab

	-- Blue "M" badge at top-right like Backpack/Journal
	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(1,0)
	badge.Position = UDim2.fromScale(1.02, -0.02)
	badge.Size = UDim2.fromScale(0.46, 0.46)
	badge.BackgroundColor3 = Color3.fromRGB(90,150,255)
	badge.Text = "M"
	badge.TextScaled = true
	badge.Font = Enum.Font.GothamBold
	badge.TextColor3 = Color3.fromRGB(255,255,255)
	badge.Parent = fab
	local badgeCorner = Instance.new("UICorner"); badgeCorner.CornerRadius = UDim.new(1,0); badgeCorner.Parent = badge
	local badgeStroke = Instance.new("UIStroke"); badgeStroke.Thickness = 2; badgeStroke.Color = Color3.fromRGB(40,80,150); badgeStroke.Parent = badge

	-- Click area (button)
	local btn = Instance.new("TextButton")
	btn.Name = "Click"
	btn.BackgroundTransparency = 1
	btn.Size = UDim2.fromScale(1,1)
	btn.Text = ""
	btn.Parent = fab

	return fab
end

---------------------------------------------------------------------
-- Panel window
---------------------------------------------------------------------
local function makePanel()
	local panel = gui:FindFirstChild("MagnetsPanel")
	if panel then return panel end

	panel = Instance.new("Frame")
	panel.Name = "MagnetsPanel"
	panel.AnchorPoint = Vector2.new(0.5,0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.50, 0.60)
	panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = gui

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Color = Color3.fromRGB(50,50,55); s.Parent = panel

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.14)
	header.Parent = panel

	local titleIcon = Instance.new("TextLabel")
	titleIcon.BackgroundTransparency = 1
	titleIcon.Size = UDim2.fromScale(0.12, 1)
	titleIcon.Position = UDim2.fromScale(0.02, 0)
	titleIcon.Text = "🧲"
	titleIcon.TextScaled = true
	titleIcon.Font = Enum.Font.GothamBold
	titleIcon.TextColor3 = Color3.fromRGB(255,90,90)
	titleIcon.Parent = header

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.68, 1)
	title.Position = UDim2.fromScale(0.12, 0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Magnets"
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(235,235,235)
	title.Parent = header

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1,0)
	close.Position = UDim2.fromScale(0.98, 0.07)
	close.Size = UDim2.fromScale(0.10, 0.86)
	close.BackgroundColor3 = Color3.fromRGB(60,60,60)
	close.Text = "X"
	close.TextScaled = true
	close.TextColor3 = Color3.new(1,1,1)
	close.Parent = header
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,8); cc.Parent = close
	close.MouseButton1Click:Connect(function()
		panel.Visible = false
		player:SetAttribute("UILocked", false)
		if UIBus then UIBus:Fire("Magnets") end
	end)

	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 0.86)
	content.Position = UDim2.fromScale(0, 0.14)
	content.Parent = panel

	local empty = Instance.new("TextLabel")
	empty.Name = "Empty"
	empty.BackgroundTransparency = 1
	empty.Size = UDim2.fromScale(1,1)
	empty.Text = "No magnets yet."
	empty.TextScaled = true
	empty.Font = Enum.Font.GothamBlack
	empty.TextColor3 = Color3.fromRGB(220,220,220)
	empty.Parent = content

	-- Grid for magnets (hidden when empty)
	local gridHolder = Instance.new("Frame")
	gridHolder.Name = "GridHolder"
	gridHolder.BackgroundTransparency = 1
	gridHolder.Size = UDim2.fromScale(0.94, 0.86)
	gridHolder.Position = UDim2.fromScale(0.03, 0.08)
	gridHolder.Visible = false
	gridHolder.Parent = content

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(8,8)
	grid.CellSize = UDim2.fromScale(0.24, 0.30)
	grid.FillDirectionMaxCells = 4
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = gridHolder

	return panel
end

---------------------------------------------------------------------
-- Data + rendering
---------------------------------------------------------------------
local currentEquipped = nil
local catalog = nil

local function render(panel)
	local content = panel.Content
	local gridHolder = content.GridHolder
	local empty = content.Empty

	for _,child in ipairs(gridHolder:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if not catalog or #catalog == 0 then
		empty.Visible = true
		gridHolder.Visible = false
		return
	end

	empty.Visible = false
	gridHolder.Visible = true

	for i,entry in ipairs(catalog) do
		local card = Instance.new("Frame")
		card.LayoutOrder = i
		card.BackgroundColor3 = Color3.fromRGB(28,28,32)
		card.Parent = gridHolder
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = card
		local st = Instance.new("UIStroke"); st.Thickness = 1.5; st.Parent = card

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.fromScale(1, 0.45)
		name.Position = UDim2.fromScale(0, 0.05)
		name.TextScaled = true
		name.TextWrapped = true
		name.Text = entry.name or entry.id or "Magnet"
		name.Font = Enum.Font.GothamBold
		name.TextColor3 = Color3.fromRGB(235,235,235)
		name.Parent = card

		local stats = Instance.new("TextLabel")
		stats.BackgroundTransparency = 1
		stats.Size = UDim2.fromScale(1, 0.28)
		stats.Position = UDim2.fromScale(0, 0.48)
		stats.TextScaled = true
		stats.TextWrapped = true
		local s = entry.stats or {}
		stats.Text = string.format("🎯 ctrl %.1f | 🎣 lure %.1f", s.control or 1, s.lure or 1)
		stats.TextColor3 = Color3.fromRGB(190,190,190)
		stats.Font = Enum.Font.Gotham
		stats.Parent = card

		local equip = Instance.new("TextButton")
		equip.Name = "Equip"
		equip.Size = UDim2.fromScale(0.9, 0.20)
		equip.Position = UDim2.fromScale(0.05, 0.75)
		equip.BackgroundColor3 = Color3.fromRGB(70,120,200)
		equip.TextScaled = true
		equip.TextColor3 = Color3.new(1,1,1)
		equip.Text = (currentEquipped == entry.id) and "Equipped" or "Equip"
		equip.Parent = card
		local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0,6); ec.Parent = equip

		equip.MouseButton1Click:Connect(function()
			if EquipMagnetRF then
				local ok, res = pcall(function()
					return EquipMagnetRF:InvokeServer(entry.id)
				end)
				if ok and type(res)=="table" and res.ok then
					currentEquipped = res.equipped
					render(panel)
				end
			end
		end)
	end
end

local function fetch()
	if not GetMagnetsRF then return end
	local ok, res = pcall(function()
		return GetMagnetsRF:InvokeServer()
	end)
	if ok and type(res)=="table" then
		catalog = res.catalog or {}
		currentEquipped = res.equipped
	end
end

---------------------------------------------------------------------
-- Open / Close
---------------------------------------------------------------------
local panel = makePanel()
local fab = makeMagnetFAB()

local function open()
	fetch()
	render(panel)
	if UIBus then UIBus:Fire("Magnets") end -- close others
	panel.Visible = true
	player:SetAttribute("UILocked", true)
end

local function close()
	panel.Visible = false
	player:SetAttribute("UILocked", false)
end

-- Close if any other window opens
UIBus.Event:Connect(function(who)
	if who ~= "Magnets" then
		close()
	end
end)

-- Toggle with button and with M
fab.Click.MouseButton1Click:Connect(function()
	if panel.Visible then close() else open() end
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		if panel.Visible then close() else open() end
	end
end)

-- Safety: if UI reloads, ensure FAB exists
makeMagnetFAB()
makePanel()
