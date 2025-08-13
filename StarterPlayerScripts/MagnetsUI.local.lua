
-- MagnetsUI.local.lua (clean)
-- Creates a blue circular "M" button next to Backpack/Journal and a simple Magnets panel.
-- No "(disable)" label. No reliance on ResetOnSpawn of PlayerScripts.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Shared UIBus (mutual exclusion with other panels)
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
	UIBus = Instance.new("BindableEvent")
	UIBus.Name = "UIBusCloseAll"
	UIBus.Parent = RS
end

-- Remotes (optional)
local GetMagnetsRF = RS:FindFirstChild("GetMagnets")
local EquipMagnetRF = RS:FindFirstChild("EquipMagnet")

-- Build / fetch ScreenGui
local pg = player:WaitForChild("PlayerGui")
local gui = pg:FindFirstChild("MagnetsUI")
if not gui then
	gui = Instance.new("ScreenGui")
	gui.Name = "MagnetsUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg
end

-- Panel (centered modal)
local panel = gui:FindFirstChild("MagnetsPanel")
if not panel then
	panel = Instance.new("Frame")
	panel.Name = "MagnetsPanel"
	panel.Size = UDim2.fromScale(0.50, 0.50)
	panel.Position = UDim2.fromScale(0.25, 0.20)
	panel.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = gui

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = panel
	local s = Instance.new("UIStroke"); s.Thickness = 2; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Color = Color3.fromRGB(60,60,64); s.Parent = panel

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundTransparency = 1
	titleBar.Size = UDim2.fromScale(1, 0.16)
	titleBar.Parent = panel

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(0.10, 1)
	icon.Position = UDim2.fromScale(0.02, 0)
	icon.Text = "🧲"
	icon.TextScaled = true
	icon.TextColor3 = Color3.fromRGB(240,240,240)
	icon.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.70, 1)
	title.Position = UDim2.fromScale(0.12, 0)
	title.Text = "Magnets"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(240,240,240)
	title.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(1,0)
	closeBtn.Size = UDim2.fromScale(0.08, 0.60)
	closeBtn.Position = UDim2.fromScale(0.98, 0.20)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	closeBtn.Text = "X"
	closeBtn.TextScaled = true
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Parent = titleBar
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,8); cc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
		player:SetAttribute("UILocked", false)
		local SetUILockState = RS:FindFirstChild("SetUILockState")
		if SetUILockState and SetUILockState:IsA("RemoteEvent") then
			SetUILockState:FireServer(false)
		end
	end)

	-- Content
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1, 0.84)
	body.Position = UDim2.fromScale(0, 0.16)
	body.Parent = panel

	local empty = Instance.new("TextLabel")
	empty.Name = "EmptyLabel"
	empty.BackgroundTransparency = 1
	empty.Size = UDim2.fromScale(1, 1)
	empty.Text = "No magnets yet."
	empty.TextScaled = true
	empty.TextColor3 = Color3.fromRGB(230,230,230)
	empty.Parent = body
end

-- FAB: blue circular "M", placed left of the Journal/Backpack cluster (bottom-right)
local fab = gui:FindFirstChild("MagnetsFAB")
if not fab then
	fab = Instance.new("TextButton")
	fab.Name = "MagnetsFAB"
	fab.AnchorPoint = Vector2.new(1,1)
	fab.Size = UDim2.fromOffset(56, 56)
	-- Place it slightly to the LEFT of the other two buttons (which are near 0.94-0.98)
	fab.Position = UDim2.fromScale(0.88, 0.95)
	fab.BackgroundColor3 = Color3.fromRGB(70, 120, 220) -- blue
	fab.Text = "M"
	fab.TextScaled = true
	fab.TextColor3 = Color3.fromRGB(255,255,255)
	fab.Parent = gui

	local r = Instance.new("UICorner"); r.CornerRadius = UDim.new(1,0); r.Parent = fab
	local st = Instance.new("UIStroke"); st.Thickness = 2; st.Color = Color3.fromRGB(30,50,90); st.Parent = fab
end

-- Behavior
local function openPanel()
	-- Mutual exclusion
	UIBus:Fire("Magnets")
	panel.Visible = true
	player:SetAttribute("UILocked", true)
	local SetUILockState = RS:FindFirstChild("SetUILockState")
	if SetUILockState and SetUILockState:IsA("RemoteEvent") then
		SetUILockState:FireServer(true)
	end

	-- Populate if catalog exists
	if GetMagnetsRF and GetMagnetsRF:IsA("RemoteFunction") then
		local ok, payload = pcall(function() return GetMagnetsRF:InvokeServer() end)
		if ok and type(payload) == "table" then
			local body = panel:FindFirstChild("Body")
			if body and body:FindFirstChild("EmptyLabel") then
				if payload.catalog and #payload.catalog > 0 then
					body.EmptyLabel.Text = "Magnets will appear here soon."
				else
					body.EmptyLabel.Text = "No magnets yet."
				end
			end
		end
	end
end

local function closePanel()
	panel.Visible = false
	player:SetAttribute("UILocked", false)
	local SetUILockState = RS:FindFirstChild("SetUILockState")
	if SetUILockState and SetUILockState:IsA("RemoteEvent") then
		SetUILockState:FireServer(false)
	end
end

fab.MouseButton1Click:Connect(function()
	if panel.Visible then closePanel() else openPanel() end
end)

UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.M then
		if panel.Visible then closePanel() else openPanel() end
	end
	-- close on ESC
	if inp.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		closePanel()
	end
end)

-- Close if another UI opens
UIBus.Event:Connect(function(who)
	if who ~= "Magnets" then
		closePanel()
	end
end)
