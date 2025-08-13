-- MagnetsUI.local.lua (updated)
-- Creates a bottom-right magnet button that matches Backpack/Journal styling,
-- positions it to the left of Journal with the same spacing,
-- uses the same font weight/size for the blue "M" badge,
-- opens the Magnets panel on click or when pressing M.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer

-- Remotes
local GetMagnetsRF = RS:FindFirstChild("GetMagnets")
local EquipMagnetRF = RS:FindFirstChild("EquipMagnet")

-- UIBus for mutual exclusion (same as Backpack/Journal)
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end

-- Tweakables: position & spacing
-- These assume Backpack is furthest right, Journal is next, Magnet will be next to Journal (further left).
local ICON_SIZE = 64
local GAP_PX = 18  -- horizontal gap between circular icons
local RIGHT_MARGIN_PX = 24  -- how far the Backpack sits from the right edge
local BOTTOM_MARGIN_PX = 26 -- distance from bottom edge
local MAGNET_EXTRA_SHIFT_PX = 48  -- + = move right,  - = move left
-- Fonts (match Backpack/Journal: GothamBold looks like their UI style)
local LETTER_FONT = Enum.Font.GothamBold

-- Find / create ScreenGui container
local screenGui = script.Parent
if not screenGui or not screenGui:IsA("ScreenGui") then
	-- If this LocalScript ended up somewhere else, create our own ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MagnetsUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = plr:WaitForChild("PlayerGui")
else
	-- Only valid for ScreenGui
	screenGui.ResetOnSpawn = false
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function pxToScaleX(px)
	return px / screenGui.AbsoluteSize.X
end
local function pxToScaleY(px)
	return px / screenGui.AbsoluteSize.Y
end

-- Compute positions so we match the typical layout:
-- Backpack (right-most), Journal to its left, Magnet to the left of Journal.
-- We don't reposition Backpack/Journal; we simply choose our own X so our gap visually matches.
local iconScaleX = pxToScaleX(ICON_SIZE)
local iconScaleY = pxToScaleY(ICON_SIZE)
local gapScaleX  = pxToScaleX(GAP_PX)
local rightScale = pxToScaleX(RIGHT_MARGIN_PX)
local bottomScale= pxToScaleY(BOTTOM_MARGIN_PX)

-- Where Journal usually sits (roughly 1 icon + 1 gap left of Backpack).
-- Magnet will sit one more gap+icon left.
local backpackX = 1 - rightScale   -- right margin (normalized)
local journalX  = backpackX - iconScaleX - gapScaleX
local magnetX   = journalX  - iconScaleX - gapScaleX + pxToScaleX(MAGNET_EXTRA_SHIFT_PX)


---------------------------------------------------------------------
-- Build circular magnet button
---------------------------------------------------------------------
local button = screenGui:FindFirstChild("MagnetButton")
if not button then
	button = Instance.new("ImageButton")
	button.Name = "MagnetButton"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
	button.Position = UDim2.new(magnetX, 0, 1 - bottomScale, 0)
	button.BackgroundColor3 = Color3.fromRGB(30,30,34)
	button.AutoButtonColor = true
	button.Image = "" -- no image, black circular background like others
	button.Parent = screenGui

	local circle = Instance.new("UICorner")
	circle.CornerRadius = UDim.new(1, 0)
	circle.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(15, 15, 16)
	stroke.Transparency = 0.15
	stroke.Parent = button

	-- Magnet pictogram in the middle (simple Unicode magnet + bolt as placeholder).
	local magnetIcon = Instance.new("TextLabel")
	magnetIcon.Name = "Icon"
	magnetIcon.BackgroundTransparency = 1
	magnetIcon.Size = UDim2.fromScale(1, 1)
	magnetIcon.Position = UDim2.fromScale(0, 0.02) -- nudge down slightly to align with others
	magnetIcon.Text = "🧲"
	magnetIcon.TextScaled = true
	magnetIcon.Font = Enum.Font.SourceSansBold
	magnetIcon.TextColor3 = Color3.fromRGB(220, 50, 50)
	magnetIcon.Parent = button

	-- Blue letter badge (top-right), same style as Backpack/Journal letters
	local letter = Instance.new("TextLabel")
	letter.Name = "Badge"
	letter.AnchorPoint = Vector2.new(0.5, 0.5)
	letter.Size = UDim2.fromScale(0.46, 0.46)  -- match Journal/Backpack
	letter.Position = UDim2.fromScale(0.84, 0.20) -- slightly lower so it matches baseline of others
	letter.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
	letter.Text = "M"
	letter.Font = LETTER_FONT
	letter.TextScaled = true
	letter.TextColor3 = Color3.fromRGB(255, 255, 255)
	letter.Parent = button

	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(1, 0)
	lc.Parent = letter

	local ls = Instance.new("UIStroke")
	ls.Thickness = 0 -- ensure no outline (matches the look you wanted)
	ls.Color = Color3.fromRGB(0,0,0)
	ls.Transparency = 1
	ls.Parent = letter
end

---------------------------------------------------------------------
-- Panel (simple placeholder, NO '(disable)' label anymore)
---------------------------------------------------------------------
local panel = screenGui:FindFirstChild("MagnetsPanel")
if not panel then
	panel = Instance.new("Frame")
	panel.Name = "MagnetsPanel"
	panel.Size = UDim2.fromScale(0.48, 0.52)
	panel.Position = UDim2.fromScale(0.26, 0.26)
	panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = screenGui

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.Color = Color3.fromRGB(60,60,65); s.Parent = panel

	local titleBar = Instance.new("TextLabel")
	titleBar.Name = "Title"
	titleBar.BackgroundTransparency = 1
	titleBar.Size = UDim2.fromScale(0.72, 0.14)
	titleBar.Position = UDim2.fromScale(0.04, 0.02)
	titleBar.TextXAlignment = Enum.TextXAlignment.Left
	titleBar.Text = "🧲  Magnets"
	titleBar.Font = Enum.Font.GothamBold
	titleBar.TextScaled = true
	titleBar.TextColor3 = Color3.fromRGB(240,240,240)
	titleBar.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Size = UDim2.fromScale(0.10, 0.14)
	closeBtn.Position = UDim2.fromScale(0.98, 0.02)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextScaled = true
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	closeBtn.Parent = panel
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,8); cc.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
		plr:SetAttribute("UILocked", false)
		local SetUILockState = RS:FindFirstChild("SetUILockState")
		if SetUILockState then SetUILockState:FireServer(false) end
	end)

	-- Content area (for future catalog/grid)
	local msg = Instance.new("TextLabel")
	msg.Name = "EmptyMessage"
	msg.BackgroundTransparency = 1
	msg.Size = UDim2.fromScale(1, 0.7)
	msg.Position = UDim2.fromScale(0, 0.18)
	msg.Text = "No magnets yet."
	msg.TextScaled = true
	msg.Font = Enum.Font.Gotham
	msg.TextColor3 = Color3.fromRGB(230,230,230)
	msg.Parent = panel
end

---------------------------------------------------------------------
-- Open / close logic
---------------------------------------------------------------------
local function openPanel()
	UIBus:Fire("Magnets") -- close others
	panel.Visible = true
	plr:SetAttribute("UILocked", true)
	local SetUILockState = RS:FindFirstChild("SetUILockState")
	if SetUILockState then SetUILockState:FireServer(true) end
end
local function closePanel()
	panel.Visible = false
	plr:SetAttribute("UILocked", false)
	local SetUILockState = RS:FindFirstChild("SetUILockState")
	if SetUILockState then SetUILockState:FireServer(false) end
end

UIBus.Event:Connect(function(who)
	if who ~= "Magnets" then
		closePanel()
	end
end)

button.MouseButton1Click:Connect(function()
	if panel.Visible then closePanel() else openPanel() end
end)

-- Keybind: M to toggle
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		if panel.Visible then closePanel() else openPanel() end
	end
end)

-- Optional: on reel open (for future), keep logger minimal/inert
local featureFlagsFolder = RS:FindFirstChild("FeatureFlags")
local function isReelV2()
	local f = featureFlagsFolder and featureFlagsFolder:FindFirstChild("ReelV2Enabled")
	return f and f.Value == true
end

local OpenReelRE = RS:FindFirstChild("OpenReel")
if OpenReelRE then
	OpenReelRE.OnClientEvent:Connect(function(payload)
		if not isReelV2() then return end
		-- If desired, we can fetch equipped magnet here for logs in the future.
		-- For now, this is disabled per your request (no behavior change).
	end)
end
