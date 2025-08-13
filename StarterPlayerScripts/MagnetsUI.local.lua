-- MagnetsUI.local.lua
-- Bottom-left circular FAB like Backpack/Journal. Keybind: M.
-- Opens a panel listing magnets from GetMagnets RF and lets the player equip via EquipMagnet RF.
-- Non-destructive: creates its own ScreenGui children only.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- UIBus (mutual exclusion with other panels like Backpack/Journal)
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end

-- Remotes
local GetMagnetsRF = RS:WaitForChild("GetMagnets", 5)
local EquipMagnetRF = RS:WaitForChild("EquipMagnet", 5)

-- Feature flags mirror (from FeatureFlagsBridge.server.lua)
local FF = RS:FindFirstChild("FeatureFlags")

-- Root GUI
local gui = script.Parent
gui.ResetOnSpawn = false
gui.Enabled = true

----------------------------------------------------------------
-- FAB (bottom-left, circle with blue "M" badge) ---------------
----------------------------------------------------------------
local fab = gui:FindFirstChild("MagnetsFAB")
if not fab then
	fab = Instance.new("TextButton")
	fab.Name = "MagnetsFAB"
	fab.AnchorPoint = Vector2.new(0, 1)
	fab.Size = UDim2.fromOffset(64, 64)
	-- Place near bottom-left, slightly to the right so it can sit beside your Journal button
	fab.Position = UDim2.fromScale(0.11, 0.95)
	fab.BackgroundColor3 = Color3.fromRGB(36, 36, 40)
	fab.Text = "🧲"
	fab.TextScaled = true
	fab.TextColor3 = Color3.new(1, 1, 1)
	fab.Parent = gui

	local fabCorner = Instance.new("UICorner")
	fabCorner.CornerRadius = UDim.new(1, 0)
	fabCorner.Parent = fab

	local fabStroke = Instance.new("UIStroke")
	fabStroke.Thickness = 2
	fabStroke.Parent = fab

	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.Size = UDim2.fromScale(0.45, 0.45)
	badge.Position = UDim2.fromScale(0.55, -0.05)
	badge.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
	badge.Text = "M"
	badge.TextScaled = true
	badge.TextColor3 = Color3.fromRGB(255, 255, 255)
	badge.Parent = fab

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(1, 0)
	bCorner.Parent = badge
end

----------------------------------------------------------------
-- Panel -------------------------------------------------------
----------------------------------------------------------------
local panel = gui:FindFirstChild("MagnetsPanel")
if not panel then
	panel = Instance.new("Frame")
	panel.Name = "MagnetsPanel"
	panel.Size = UDim2.fromScale(0.50, 0.62)
	panel.Position = UDim2.fromScale(0.25, 0.19)
	panel.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = gui

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.6, 0.12)
	title.Position = UDim2.fromScale(0.03, 0.02)
	title.Text = "🧲 Magnets"
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	-- Small flag hint (moved left so it doesn't sit behind the X)
	local hint = Instance.new("TextLabel")
	hint.Name = "FlagHint"
	hint.BackgroundTransparency = 1
	hint.Size = UDim2.fromScale(0.35, 0.10)
	hint.Position = UDim2.fromScale(0.65, 0.04)
	hint.TextScaled = true
	hint.TextColor3 = Color3.fromRGB(200, 200, 200)
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Parent = panel
	hint.Visible = false  -- toggled by feature flag

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Size = UDim2.fromScale(0.08, 0.12)
	closeBtn.Position = UDim2.fromScale(0.98, 0.02)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	closeBtn.Text = "X"
	closeBtn.TextScaled = true
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Parent = panel
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
		player:SetAttribute("UILocked", false)
		local SetUILockState = RS:FindFirstChild("SetUILockState")
		if SetUILockState and SetUILockState:IsA("RemoteEvent") then
			SetUILockState:FireServer(false)
		end
	end)

	-- Grid
	local gridFrame = Instance.new("Frame")
	gridFrame.Name = "Grid"
	gridFrame.Size = UDim2.fromScale(0.94, 0.78)
	gridFrame.Position = UDim2.fromScale(0.03, 0.18)
	gridFrame.BackgroundTransparency = 1
	gridFrame.Parent = panel

	local uiGrid = Instance.new("UIGridLayout")
	uiGrid.CellPadding = UDim2.fromOffset(8, 8)
	uiGrid.CellSize = UDim2.fromScale(0.30, 0.30) -- 3 columns
	uiGrid.FillDirectionMaxCells = 3
	uiGrid.SortOrder = Enum.SortOrder.LayoutOrder
	uiGrid.Parent = gridFrame

	-- Empty message
	local empty = Instance.new("TextLabel")
	empty.Name = "Empty"
	empty.BackgroundTransparency = 1
	empty.Size = UDim2.fromScale(1, 0.2)
	empty.Position = UDim2.fromScale(0, 0.40)
	empty.Text = "No magnets yet."
	empty.TextScaled = true
	empty.TextColor3 = Color3.fromRGB(225, 225, 225)
	empty.Visible = false
	empty.Parent = gridFrame
end

----------------------------------------------------------------
-- Helpers -----------------------------------------------------
----------------------------------------------------------------
local function setFlagHint()
	local hint = panel:FindFirstChild("FlagHint")
	if not hint then return end
	local enabled = false
	if FF and FF:FindFirstChild("MagnetsEnabled") then
		enabled = FF.MagnetsEnabled.Value
		FF.MagnetsEnabled:GetPropertyChangedSignal("Value"):Connect(function()
			setFlagHint()
		end)
	end
	if enabled then
		hint.Text = ""
		hint.Visible = false
	else
		hint.Text = "(disabled)"
		hint.Visible = true
	end
end

local function clearGrid()
	local grid = panel:FindFirstChild("Grid")
	if not grid then return end
	for _, child in ipairs(grid:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
			if child.Name ~= "Empty" and child.Name ~= "UIGridLayout" then
				child:Destroy()
			end
		end
	end
end

local function addCard(info, equippedId)
	local grid = panel:FindFirstChild("Grid")
	if not grid then return end

	local card = Instance.new("Frame")
	card.Name = "Card_" .. (info.id or "unknown")
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = card
	local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Parent = card

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.94, 0.34)
	name.Position = UDim2.fromScale(0.03, 0.02)
	name.TextScaled = true
	name.TextWrapped = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = tostring(info.name or info.id or "Magnet")
	name.TextColor3 = Color3.fromRGB(250, 250, 250)
	name.Parent = card

	local stats = Instance.new("TextLabel")
	stats.BackgroundTransparency = 1
	stats.Size = UDim2.fromScale(0.94, 0.40)
	stats.Position = UDim2.fromScale(0.03, 0.38)
	stats.TextScaled = true
	stats.TextWrapped = true
	stats.TextXAlignment = Enum.TextXAlignment.Left
	local st = info.stats or {}
	stats.Text = string.format("Lure %s  Rarity %s\nControl %s  Weight %s\nStability %s",
		tostring(st.lure or st.speed or 1),
		tostring(st.rarity or st.luck or 1),
		tostring(st.control or 1),
		tostring(st.weight or st.maxWeight or 1),
		tostring(st.stability or 1)
	)
	stats.TextColor3 = Color3.fromRGB(210, 210, 210)
	stats.Parent = card

	local equip = Instance.new("TextButton")
	equip.Name = "Equip"
	equip.Size = UDim2.fromScale(0.50, 0.20)
	equip.Position = UDim2.fromScale(0.25, 0.76)
	equip.BackgroundColor3 = Color3.fromRGB(60, 120, 80)
	equip.TextScaled = true
	equip.TextColor3 = Color3.new(1,1,1)
	local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0, 8); ec.Parent = equip
	equip.Parent = card

	local id = info.id
	if id and equippedId == id then
		equip.Text = "✓ Equipped"
		equip.BackgroundColor3 = Color3.fromRGB(80, 140, 100)
		equip.AutoButtonColor = false
	else
		equip.Text = "Equip"
	end

	equip.MouseButton1Click:Connect(function()
		if not EquipMagnetRF then return end
		local ok, res = pcall(function()
			return EquipMagnetRF:InvokeServer(id)
		end)
		if ok and type(res)=="table" and res.ok then
			-- refresh after equip
			task.defer(function()
				local ok2, payload = pcall(function()
					return GetMagnetsRF and GetMagnetsRF:InvokeServer()
				end)
				if ok2 and type(payload)=="table" then
					local cat = payload.catalog or {}
					clearGrid()
					if #cat == 0 then
						panel.Grid.Empty.Visible = true
					else
						panel.Grid.Empty.Visible = false
						for _, m in ipairs(cat) do
							addCard(m, payload.equipped)
						end
					end
				end
			end)
		end
	end)

	card.Parent = grid
end

local function refresh()
	setFlagHint()

	if not GetMagnetsRF then
		-- still show a graceful empty state
		panel.Grid.Empty.Text = "Magnets not available."
		panel.Grid.Empty.Visible = true
		return
	end

	local ok, payload = pcall(function()
		return GetMagnetsRF:InvokeServer()
	end)
	if not ok or type(payload) ~= "table" then
		panel.Grid.Empty.Text = "Failed to load magnets."
		panel.Grid.Empty.Visible = true
		return
	end

	local cat = payload.catalog or {}
	clearGrid()
	if #cat == 0 then
		panel.Grid.Empty.Text = "No magnets yet."
		panel.Grid.Empty.Visible = true
	else
		panel.Grid.Empty.Visible = false
		for _, info in ipairs(cat) do
			addCard(info, payload.equipped)
		end
	end
end

----------------------------------------------------------------
-- Open/Close + keybind ---------------------------------------
----------------------------------------------------------------
local function open()
	UIBus:Fire("Magnets") -- ask others to close
	panel.Visible = true
	player:SetAttribute("UILocked", true)
	local SetUILockState = RS:FindFirstChild("SetUILockState")
	if SetUILockState and SetUILockState:IsA("RemoteEvent") then
		SetUILockState:FireServer(true)
	end
	refresh()
end

local function close()
	panel.Visible = false
	player:SetAttribute("UILocked", false)
end

fab.MouseButton1Click:Connect(function()
	if panel.Visible then close() else open() end
end)

UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.M then
		if panel.Visible then close() else open() end
	end
end)

-- mutual exclusion
UIBus.Event:Connect(function(who)
	if who ~= "Magnets" then
		close()
	end
end)

-- Safety: if FeatureFlags changes after open/close
if FF then
	if FF:FindFirstChild("MagnetsEnabled") then
		FF.MagnetsEnabled:GetPropertyChangedSignal("Value"):Connect(function()
			setFlagHint()
		end)
	end
end
