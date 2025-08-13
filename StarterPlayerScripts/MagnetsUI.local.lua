-- MagnetsUI.local.lua (updated)
-- Creates a round magnet FAB with blue "M" badge, aligned left of Journal/Backpack.
-- Toggles with M. Opens simple Magnets panel using existing RFs.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

-- === utilities =====================================================
local function findButtonByName(name)
	for _, gui in ipairs(pg:GetChildren()) do
		if gui:IsA("ScreenGui") then
			local btn = gui:FindFirstChild(name, true)
			if btn and btn:IsA("TextButton") then
				return btn
			end
		end
	end
	return nil
end

local function viewport()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1920,1080)
	return vs.X, vs.Y
end

local function toScaleFromAbs(absPos, anchor)
	local vx, vy = viewport()
	local sx = absPos.X / vx
	local sy = absPos.Y / vy
	return UDim2.fromScale(sx, sy), anchor or Vector2.new(0,0)
end

-- === screen gui container =========================================
local screen = script.Parent
if not screen or not screen:IsA("ScreenGui") then
	screen = Instance.new("ScreenGui")
	screen.Name = "MagnetsUI"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = pg
end

-- === FAB button (bottom-right line with the others) ================
local fab = screen:FindFirstChild("MagnetsFAB")
if not fab then
	fab = Instance.new("TextButton")
	fab.Name = "MagnetsFAB"
	fab.AutoButtonColor = true
	fab.AnchorPoint = Vector2.new(0.5, 0.5)
	fab.Size = UDim2.fromOffset(64, 64)
	fab.BackgroundColor3 = Color3.fromRGB(28, 28, 32) -- same dark round base
	fab.Text = "" -- icon only
	fab.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = fab

	-- Magnet glyph (unicode horseshoe magnet) inside the circle
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1, 1)
	icon.Position = UDim2.fromScale(0, 0)
	icon.Text = utf8.char(0x1F9F2) -- 🧲
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.fromRGB(230, 70, 70)
	icon.Parent = fab

	-- Blue "M" badge (match Backpack/Journal style: solid fill, no outline)
	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Size = UDim2.fromScale(0.45, 0.45)
	badge.Position = UDim2.fromScale(0.78, 0.18)
	badge.BackgroundColor3 = Color3.fromRGB(90,150,255)
	badge.Text = "M"
	badge.TextScaled = true
	badge.Font = Enum.Font.GothamBold
	badge.TextColor3 = Color3.fromRGB(255,255,255)
	badge.Parent = fab

	local bcorner = Instance.new("UICorner")
	bcorner.CornerRadius = UDim.new(1, 0)
	bcorner.Parent = badge
end

-- Position the magnet button based on existing Journal/Backpack spacing
local function placeFab()
	local journal = findButtonByName("JournalFAB")
	local backpack = findButtonByName("BackpackFAB")

	if journal and backpack then
		-- Compute spacing between Journal and Backpack, then place Magnets one "step" to the left of Journal.
		local jPos = journal.AbsolutePosition
		local bPos = backpack.AbsolutePosition
		local spacing = math.abs(bPos.X - jPos.X)
		local x = jPos.X - spacing
		local y = jPos.Y  -- align row
		local pos = UDim2.fromOffset(x + 32, y + 32) -- center compensation (64x64)
		fab.AnchorPoint = Vector2.new(0.5, 0.5)
		fab.Position = pos
	else
		-- Fallback: bottom row, to the left of typical cluster
		fab.AnchorPoint = Vector2.new(1,1)
		fab.Position = UDim2.fromScale(0.82, 0.95)
	end
end
placeFab()
-- Re-place on resize
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.defer(placeFab)
end)
RunService.Heartbeat:Connect(function() -- try a few frames until others spawn
	if not findButtonByName("BackpackFAB") or not findButtonByName("JournalFAB") then return end
	placeFab()
end)

-- === Panel =========================================================
local panel = screen:FindFirstChild("MagnetsPanel")
if not panel then
	panel = Instance.new("Frame")
	panel.Name = "MagnetsPanel"
	panel.Size = UDim2.fromScale(0.50, 0.60)
	panel.Position = UDim2.fromScale(0.25, 0.20)
	panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = screen

	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,12); pc.Parent = panel
	local ps = Instance.new("UIStroke"); ps.Thickness = 2; ps.Parent = panel

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(0.7, 0.12)
	header.Position = UDim2.fromScale(0.04, 0.02)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "🧲  Magnets"
	header.TextScaled = true
	header.TextColor3 = Color3.fromRGB(255,255,255)
	header.Parent = panel

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
	closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1, 0.8)
	body.Position = UDim2.fromScale(0, 0.18)
	body.Text = "No magnets yet."
	body.TextScaled = true
	body.TextColor3 = Color3.fromRGB(210,210,210)
	body.Parent = panel
end

-- === Toggle/open ===================================================
local function open() panel.Visible = true end
local function close() panel.Visible = false end
fab.MouseButton1Click:Connect(function() if panel.Visible then close() else open() end end)

UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.M then
		if panel.Visible then close() else open() end
	end
end)

-- === Hook UIBusCloseAll (if present) ===============================
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end
UIBus.Event:Connect(function(who)
	if who ~= "Magnets" then close() end
end)
