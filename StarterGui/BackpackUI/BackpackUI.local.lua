-- BackpackUI.local.lua
-- 5x5, no stacking, tiny weight; right-click → Delete popup.
-- Mutually exclusive with Journal via UIBusCloseAll.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local SetUILockState = RS:WaitForChild("SetUILockState")
local RequestBackpack   = RS:WaitForChild("RequestBackpack")
local BackpackDataEvent = RS:WaitForChild("BackpackData")
local RemoveItemRE      = RS:WaitForChild("RemoveBackpackItem")

-- UIBus
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then UIBus = Instance.new("BindableEvent"); UIBus.Name = "UIBusCloseAll"; UIBus.Parent = RS end

local RARITY_COLORS = {
	Common    = Color3.fromRGB(235,235,235),
	Rare      = Color3.fromRGB(90,150,255),
	Epic      = Color3.fromRGB(180,110,255),
	Legendary = Color3.fromRGB(255,210,90),
	Mythic    = Color3.fromRGB(255,0,0),
}
local RARITY_OUTLINE = {
	Common    = Color3.fromRGB(80,80,80),
	Rare      = Color3.fromRGB(50,80,150),
	Epic      = Color3.fromRGB(110,70,160),
	Legendary = Color3.fromRGB(140,110,40),
	Mythic    = Color3.fromRGB(150,0,0),
}
local function rarityColor(r)
	return RARITY_COLORS[r] or RARITY_COLORS.Common,
	RARITY_OUTLINE[r] or RARITY_OUTLINE.Common
end

local gui = script.Parent
gui.ResetOnSpawn = false
gui.Enabled = true

-- Panel
local panel = gui:FindFirstChild("BackpackPanel")
if not panel then
	panel = Instance.new("Frame")
	panel.Name = "BackpackPanel"
	panel.Size = UDim2.fromScale(0.50, 0.60)
	panel.Position = UDim2.fromScale(0.25, 0.20)
	panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = gui
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.6, 0.12)
	title.Position = UDim2.fromScale(0.03, 0.02)
	title.Text = "🎒 Backpack"
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

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
	closeBtn.MouseButton1Click:Connect(function() panel.Visible = false; player:SetAttribute("UILocked", false)

	-- Sell Anywhere (if owned)
	local sellBtn = Instance.new("TextButton")
	sellBtn.Name = "SellBtn"
	sellBtn.Size = UDim2.fromScale(0.14, 0.10)
	sellBtn.Position = UDim2.fromScale(0.78, 0.06)
	sellBtn.BackgroundColor3 = Color3.fromRGB(60,120,80)
	sellBtn.Text = "Sell"
	sellBtn.TextScaled = true
	sellBtn.TextColor3 = Color3.new(1,1,1)
	sellBtn.ZIndex = 10
	sellBtn.Parent = panel
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,8); sc.Parent = sellBtn

	local SellAnywhereRE = RS:WaitForChild("SellAnywhere")
	sellBtn.MouseButton1Click:Connect(function()
		SellAnywhereRE:FireServer()
	end)
	SetUILockState:FireServer(false) end)

	-- Grid 5x5
	local gridFrame = Instance.new("Frame")
	gridFrame.Name = "Grid"
	gridFrame.Size = UDim2.fromScale(0.94, 0.78)
	gridFrame.Position = UDim2.fromScale(0.03, 0.18)
	gridFrame.BackgroundTransparency = 1
	gridFrame.Parent = panel

	local uiGrid = Instance.new("UIGridLayout")
	uiGrid.CellPadding = UDim2.fromOffset(8, 8)
	uiGrid.CellSize = UDim2.fromScale(0.19, 0.19)
	uiGrid.FillDirectionMaxCells = 5
	uiGrid.SortOrder = Enum.SortOrder.LayoutOrder
	uiGrid.Parent = gridFrame
end

-- FAB (bottom-right)
local fab = gui:FindFirstChild("BackpackFAB")
if not fab then
	fab = Instance.new("TextButton")
	fab.Name = "BackpackFAB"
	fab.AnchorPoint = Vector2.new(1,1)
	fab.Size = UDim2.fromOffset(64, 64)
	fab.Position = UDim2.fromScale(0.97, 0.95)
	fab.BackgroundColor3 = Color3.fromRGB(36,36,40)
	fab.Text = "🎒"
	fab.TextScaled = true
	fab.TextColor3 = Color3.new(1,1,1)
	fab.Parent = gui
	local fabCorner = Instance.new("UICorner"); fabCorner.CornerRadius = UDim.new(1,0); fabCorner.Parent = fab
	local fabStroke = Instance.new("UIStroke"); fabStroke.Thickness = 2; fabStroke.Parent = fab

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromScale(0.45, 0.45)
	badge.Position = UDim2.fromScale(0.55, -0.05)
	badge.BackgroundColor3 = Color3.fromRGB(90,150,255)
	badge.Text = "B"
	badge.TextScaled = true
	badge.TextColor3 = Color3.fromRGB(255,255,255)
	badge.Parent = fab
	local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(1,0); bCorner.Parent = badge
end

-- State
local entries = {} -- array of {id,name,lb,rarity}
local contextPopup -- delete popup

local function closePopup()
	if contextPopup then contextPopup:Destroy(); contextPopup = nil end
end

local function clearGrid()
	closePopup()
	local grid = panel:FindFirstChild("Grid")
	for _,child in ipairs(grid:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function makeDeletePopup(parentSlotFrame, itemId)
	closePopup()
	contextPopup = Instance.new("Frame")
	contextPopup.Size = UDim2.fromScale(0.32, 0.28)
	contextPopup.AnchorPoint = Vector2.new(0,0)
	-- place near the slot (right-bottom)
	local absPos = parentSlotFrame.AbsolutePosition
	local absSize = parentSlotFrame.AbsoluteSize
	contextPopup.Position = UDim2.fromOffset(absPos.X + absSize.X + 8, absPos.Y + absSize.Y*0.1)
	contextPopup.BackgroundColor3 = Color3.fromRGB(22,22,24)
	contextPopup.BackgroundTransparency = 0.05
	contextPopup.ZIndex = 200
	contextPopup.Parent = gui
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = contextPopup
	local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Parent = contextPopup

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0.55)
	label.Position = UDim2.fromScale(0, 0.05)
	label.Text = "Delete this item?"
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(230,230,230)
	label.ZIndex = 201
	label.Parent = contextPopup

	local del = Instance.new("TextButton")
	del.Size = UDim2.fromScale(0.9, 0.35)
	del.Position = UDim2.fromScale(0.05, 0.60)
	del.BackgroundColor3 = Color3.fromRGB(180,60,60)
	del.Text = "Delete"
	del.TextScaled = true
	del.TextColor3 = Color3.fromRGB(255,255,255)
	del.ZIndex = 201
	del.Parent = contextPopup
	local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0,6); dc.Parent = del

	del.MouseButton1Click:Connect(function()
		RemoveItemRE:FireServer(itemId)
		closePopup()
	end)
end

local function addSlot(it, index)
	local grid = panel.Grid
	local frame = Instance.new("Frame")
	frame.LayoutOrder = index or 0
	frame.BackgroundColor3 = Color3.fromRGB(28,28,32)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = frame
	local s = Instance.new("UIStroke"); s.Thickness = 1.2; s.Parent = frame

	-- Name (rarity-colored)
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.9, 0.55)
	name.Position = UDim2.fromScale(0.05, 0.10)
	name.TextScaled = true
	name.TextWrapped = true
	name.Text = it.name or "?"
	name.Parent = frame
	local fg, ol = rarityColor(it.rarity or "Common")
	name.TextColor3 = fg
	local ns = Instance.new("UIStroke"); ns.Thickness = 1; ns.Color = ol; ns.Parent = name

	-- Tiny weight bottom-right
	local w = Instance.new("TextLabel")
	w.BackgroundTransparency = 1
	w.AnchorPoint = Vector2.new(1,1)
	w.Size = UDim2.fromScale(0.45, 0.25)
	w.Position = UDim2.fromScale(0.95, 0.93)
	w.TextScaled = true
	w.TextColor3 = Color3.fromRGB(220,220,220)
	w.Text = (it.lb and string.format("%.2f lb", it.lb)) or ""
	w.Parent = frame

	-- Right-click to open delete popup
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			makeDeletePopup(frame, it.id)
		end
	end)

	frame.Parent = grid
end

local function refresh()
	clearGrid()
	for i,it in ipairs(entries) do
		addSlot(it, i)
	end
end

-- open/close (mutual exclusion)
local function open()
	UIBus:Fire("Backpack") -- closes Journal
	panel.Visible = true
	player:SetAttribute("UILocked", true)
	SetUILockState:FireServer(true)
	RequestBackpack:FireServer()
end
local function close()
	panel.Visible = false
	player:SetAttribute("UILocked", false)
	closePopup()
end
UIBus.Event:Connect(function(who) if who ~= "Backpack" then close() end end)

-- Close popup on outside click / ESC
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.Escape then closePopup() end
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		-- if clicked outside popup, close it
		if contextPopup then
			local pos = UserInputService:GetMouseLocation()
			local within = pos.X >= contextPopup.AbsolutePosition.X
				and pos.X <= contextPopup.AbsolutePosition.X + contextPopup.AbsoluteSize.X
				and pos.Y >= contextPopup.AbsolutePosition.Y
				and pos.Y <= contextPopup.AbsolutePosition.Y + contextPopup.AbsoluteSize.Y
			if not within then closePopup() end
		end
	end
end)

fab.MouseButton1Click:Connect(function() if panel.Visible then close() else open() end end)
UserInputService.InputBegan:Connect(function(inp) if inp.KeyCode == Enum.KeyCode.B then if panel.Visible then close() else open() end end end)

-- data
BackpackDataEvent.OnClientEvent:Connect(function(payload)
	entries = (payload and payload.items) or {}
	refresh()
end)
