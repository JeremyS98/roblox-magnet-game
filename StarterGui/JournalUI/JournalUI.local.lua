-- JournalUI.local.lua (panel + FAB; paging fixed)

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local SetUILockState = RS:WaitForChild("SetUILockState")

local RequestJournal  = RS:WaitForChild("RequestJournal")
local JournalData     = RS:WaitForChild("JournalData")
local JournalDiscover = RS:WaitForChild("JournalDiscover")
local RequestJournalDetails = RS:WaitForChild("RequestJournalDetails")

-- UIBus for mutual exclusion with other UIs
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end

local WHITE = Color3.fromRGB(255,255,255)
local RARITY_COLORS  = {
	Common    = Color3.fromRGB(235,235,235),
	Rare      = Color3.fromRGB(90,150,255),
	Epic      = Color3.fromRGB(180,110,255),
	Legendary = Color3.fromRGB(255,210,90),
	Mythic    = Color3.fromRGB(255,0,0),
}

-- ===== Root GUI =====
local gui = script.Parent
gui.ResetOnSpawn = false
gui.Enabled = true

-- ===== Journal Panel =====
local panel = Instance.new("Frame")
panel.Name = "JournalPanel"
panel.Size = UDim2.fromScale(0.56, 0.64)
panel.Position = UDim2.fromScale(0.12, 0.18)
panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui

-- ===== Details Panel (right side) =====
local details = Instance.new("Frame")
details.Name = "DetailsPanel"
details.Size = UDim2.fromScale(0.26, 0.64)
details.Position = UDim2.fromScale(0.70, 0.18)
details.BackgroundColor3 = Color3.fromRGB(18,18,20)
details.BackgroundTransparency = 0.05
details.Visible = false
details.Parent = gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = details
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Parent = details
end

local dName   = Instance.new("TextLabel"); dName.Name="Name"; dName.BackgroundTransparency=1; dName.Size=UDim2.fromScale(0.92, 0.14); dName.Position=UDim2.fromScale(0.04, 0.02); dName.TextScaled=true; dName.TextXAlignment=Enum.TextXAlignment.Left; dName.TextColor3=WHITE; dName.Parent=details
local dFound  = Instance.new("TextLabel"); dFound.Name="Found"; dFound.BackgroundTransparency=1; dFound.Size=UDim2.fromScale(0.92, 0.10); dFound.Position=UDim2.fromScale(0.04, 0.18); dFound.TextScaled=true; dFound.TextXAlignment=Enum.TextXAlignment.Left; dFound.TextColor3=WHITE; dFound.Parent=details
local dBest   = Instance.new("TextLabel"); dBest.Name="Best"; dBest.BackgroundTransparency=1; dBest.Size=UDim2.fromScale(0.92, 0.10); dBest.Position=UDim2.fromScale(0.04, 0.30); dBest.TextScaled=true; dBest.TextXAlignment=Enum.TextXAlignment.Left; dBest.TextColor3=WHITE; dBest.Parent=details
local dWorld  = Instance.new("TextLabel"); dWorld.Name="World"; dWorld.BackgroundTransparency=1; dWorld.Size=UDim2.fromScale(0.92, 0.10); dWorld.Position=UDim2.fromScale(0.04, 0.42); dWorld.TextScaled=true; dWorld.TextXAlignment=Enum.TextXAlignment.Left; dWorld.TextColor3=WHITE; dWorld.Parent=details

local dDesc   = Instance.new("TextLabel"); dDesc.Name="Desc"; dDesc.BackgroundTransparency=1; dDesc.Size=UDim2.fromScale(0.92, 0.30); dDesc.Position=UDim2.fromScale(0.04, 0.56); dDesc.TextWrapped=true; dDesc.TextScaled=true; dDesc.TextXAlignment=Enum.TextXAlignment.Left; dDesc.TextYAlignment=Enum.TextYAlignment.Top; dDesc.TextColor3=WHITE; dDesc.Parent=details

local function showDetails(name, rarity)
	local payload = RequestJournalDetails:InvokeServer(name)
	local when = "Unknown"
	if payload and payload.found and payload.firstAt and payload.firstAt > 0 then
		when = os.date("%Y-%m-%d %H:%M", payload.firstAt)
	end
	dName.Text  = string.format("%s  (%s)", name or "?", rarity or "")
	dFound.Text = "Discovered: " .. when
	dBest.Text  = string.format("Largest: %s lb", tostring(payload and payload.maxLb or 0))
	dWorld.Text = "Location: " .. ((payload and payload.world) or "World One")
	dDesc.Text  = payload and payload.desc or "—"
	details.Visible = true
end

do
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,12); corner.Parent = panel
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Parent = panel
end

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.fromScale(0.6, 0.12)
title.Position = UDim2.fromScale(0.03, 0.02)
title.Text = "📓 Journal"
title.TextScaled = true
title.TextColor3 = WHITE
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
closeBtn.TextColor3 = WHITE
closeBtn.Parent = panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = closeBtn end

local gridFrame = Instance.new("Frame")
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

local pageLabel = Instance.new("TextLabel")
pageLabel.BackgroundTransparency = 1
pageLabel.Size = UDim2.fromScale(0.12, 0.12)
pageLabel.Position = UDim2.fromScale(0.62, 0.02)
pageLabel.TextScaled = true
pageLabel.TextColor3 = Color3.fromRGB(220,220,220)
pageLabel.Text = "1/1"
pageLabel.Parent = panel

local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.fromScale(0.07, 0.12)
prevBtn.Position = UDim2.fromScale(0.72, 0.02)
prevBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
prevBtn.Text = "<"
prevBtn.TextScaled = true
prevBtn.TextColor3 = WHITE
prevBtn.Parent = panel
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=prevBtn end

local nextBtn = Instance.new("TextButton")
nextBtn.Size = UDim2.fromScale(0.07, 0.12)
nextBtn.Position = UDim2.fromScale(0.80, 0.02)
nextBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
nextBtn.Text = ">"
nextBtn.TextScaled = true
nextBtn.TextColor3 = WHITE
nextBtn.Parent = panel
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=nextBtn end

-- ===== FAB 📓 =====
local fab = Instance.new("TextButton")
fab.Name = "JournalFAB"
fab.AnchorPoint = Vector2.new(1,1)
fab.Size = UDim2.fromOffset(64, 64)
fab.Position = UDim2.fromScale(0.90, 0.95)
fab.BackgroundColor3 = Color3.fromRGB(36,36,40)
fab.Text = "📓"
fab.TextScaled = true
fab.TextColor3 = WHITE
fab.Parent = gui
do
	local fabCorner = Instance.new("UICorner"); fabCorner.CornerRadius = UDim.new(1,0); fabCorner.Parent = fab
	local fabStroke = Instance.new("UIStroke"); fabStroke.Thickness = 2; fabStroke.Parent = fab
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromScale(0.45, 0.45)
	badge.Position = UDim2.fromScale(0.55, -0.05)
	badge.BackgroundColor3 = Color3.fromRGB(90,150,255)
	badge.Text = "J"
	badge.TextScaled = true
	badge.TextColor3 = WHITE
	badge.Parent = fab
	local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(1,0); bCorner.Parent = badge
end

-- ===== Slots =====
local function makeSlot(entry)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(28,28,32)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = f
	local s = Instance.new("UIStroke"); s.Thickness = 1.3; s.Parent = f

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.9, 0.6)
	name.Position = UDim2.fromScale(0.05, 0.2)
	name.TextScaled = true
	name.TextWrapped = true
	name.Parent = f
	name.Text = entry.name or "?"
	name.TextColor3 = RARITY_COLORS[entry.rarity or "Common"] or WHITE
	local ns = Instance.new("UIStroke"); ns.Thickness = 1; ns.Color = Color3.fromRGB(0,0,0); ns.Parent = name
	
	local btn = Instance.new("TextButton"); btn.BackgroundTransparency=1; btn.Size=UDim2.fromScale(1,1); btn.Text=""; btn.Parent=f; btn.MouseButton1Click:Connect(function() showDetails(entry.name, entry.rarity) end)
return f
end

local function makePlaceholderSlot(rarity)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(28,28,32)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = f
	local s = Instance.new("UIStroke"); s.Thickness = 1.3; s.Parent = f

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.9, 0.6)
	name.Position = UDim2.fromScale(0.05, 0.2)
	name.TextScaled = true
	name.TextWrapped = true
	name.Text = "?"
	name.Parent = f
	name.TextColor3 = RARITY_COLORS[rarity or "Common"] or WHITE
	local ns = Instance.new("UIStroke"); ns.Thickness = 1; ns.Color = Color3.fromRGB(0,0,0); ns.Parent = name
	return f
end

-- ===== State / paging =====
local fullCatalog, entries = {}, {}
local page, perPage = 1, 25
local function pagesCount() return math.max(1, math.ceil(#entries / perPage)) end
local function rebuildVisible()
	entries = {}
	for _,e in ipairs(fullCatalog) do if e.found then table.insert(entries, e) end end
	for _,e in ipairs(fullCatalog) do if not e.found then table.insert(entries, {name="?", rarity=e.rarity, ph=true}) end end
	page = 1
end

local function refresh()
	for _,child in ipairs(gridFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	local total = #entries
	local pages = pagesCount()
	if page > pages then page = pages end
	pageLabel.Text = string.format("%d/%d", page, pages)

	local startIdx = (page-1)*perPage + 1
	local endIdx = math.min(total, page*perPage)
	for i = startIdx, endIdx do
		local e = entries[i]
		;(e.ph and makePlaceholderSlot(e.rarity) or makeSlot(e)).Parent = gridFrame
	end
end

-- ===== Open/Close =====
local function open()
	UIBus:Fire("Journal")
	panel.Visible = true
	player:SetAttribute("UILocked", true)
	SetUILockState:FireServer(true)
	RequestJournal:FireServer()
end
local function close()
	panel.Visible = false
	player:SetAttribute("UILocked", false)
	SetUILockState:FireServer(false)
end
UIBus.Event:Connect(function(who) if who ~= "Journal" then close() end end)
fab.MouseButton1Click:Connect(function() if panel.Visible then close() else open() end end)
UserInputService.InputBegan:Connect(function(inp)
	if inp.KeyCode == Enum.KeyCode.J then
		if panel.Visible then close() else open() end
	end
end)
closeBtn.MouseButton1Click:Connect(function() close() end)

-- ===== Paging buttons (FIX) =====
prevBtn.MouseButton1Click:Connect(function()
	if page > 1 then
		page -= 1
		refresh()
	end
end)
nextBtn.MouseButton1Click:Connect(function()
	if page < pagesCount() then
		page += 1
		refresh()
	end
end)

-- ===== Data =====
JournalData.OnClientEvent:Connect(function(payload)
	fullCatalog = payload or {}
	rebuildVisible()
	refresh()
end)

JournalDiscover.OnClientEvent:Connect(function(info)
	if typeof(info) == "table" and info.name and info.rarity then
		for _, e in ipairs(fullCatalog) do
			if e.name == info.name then e.found = true break end
		end
		rebuildVisible(); refresh()
	end
end)
