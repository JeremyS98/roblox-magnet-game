-- MagnetsUI.local.lua
-- Minimal UI to view/equip magnets (scaffolding). Matches backpack/journal FAB style.
-- Places an "M" blue circular button next to Journal/Backpack (bottom-right cluster).
-- Removes any "(disable)" label in the panel header.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- UIBus (mutual exclusion with other panels)
local UIBus = RS:FindFirstChild("UIBusCloseAll")
if not UIBus then
    UIBus = Instance.new("BindableEvent")
    UIBus.Name = "UIBusCloseAll"
    UIBus.Parent = RS
end

local FeatureFlagsFolder = RS:FindFirstChild("FeatureFlags")
local ReelV2Flag = FeatureFlagsFolder and FeatureFlagsFolder:FindFirstChild("MagnetsEnabled")

local gui = script.Parent
gui.ResetOnSpawn = false
gui.Enabled = true

-- Root panel --------------------------------------------------------------
local panel = gui:FindFirstChild("MagnetsPanel")
if not panel then
    panel = Instance.new("Frame")
    panel.Name = "MagnetsPanel"
    panel.Size = UDim2.fromScale(0.48, 0.54)
    panel.Position = UDim2.fromScale(0.26, 0.22)
    panel.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    panel.BackgroundTransparency = 0.08
    panel.Visible = false
    panel.Parent = gui

    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = panel
    local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(60, 60, 64); stroke.Parent = panel

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.fromScale(1, 0.16)
    header.BackgroundTransparency = 1
    header.Parent = panel

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(0.8, 1)
    title.Position = UDim2.fromScale(0.04, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "🧲  Magnets"
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(240, 240, 240)
    title.Parent = header

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.fromScale(0.98, 0.08)
    closeBtn.Size = UDim2.fromScale(0.1, 0.84)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeBtn.Text = "X"
    closeBtn.TextScaled = true
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Parent = header
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        player:SetAttribute("UILocked", false)
        local SetUILockState = RS:FindFirstChild("SetUILockState")
        if SetUILockState then SetUILockState:FireServer(false) end
    end)

    -- Body placeholder
    local body = Instance.new("TextLabel")
    body.Name = "Empty"
    body.BackgroundTransparency = 1
    body.Size = UDim2.fromScale(1, 0.84)
    body.Position = UDim2.fromScale(0, 0.16)
    body.Text = "No magnets yet."
    body.TextScaled = true
    body.TextWrapped = true
    body.TextColor3 = Color3.fromRGB(225, 225, 225)
    body.Parent = panel
end

-- Blue circular FAB with white 'M' (bottom-right cluster) -----------------
local fab = gui:FindFirstChild("MagnetsFAB")
if not fab then
    fab = Instance.new("Frame")
    fab.Name = "MagnetsFAB"
    fab.AnchorPoint = Vector2.new(1, 1)
    -- Position it just to the left of Journal/Backpack buttons (approx).
    fab.Position = UDim2.fromScale(0.88, 0.95)
    fab.Size = UDim2.fromOffset(56, 56)
    fab.BackgroundColor3 = Color3.fromRGB(77, 143, 255) -- same blue used for Journal
    fab.Parent = gui

    local round = Instance.new("UICorner"); round.CornerRadius = UDim.new(1, 0); round.Parent = fab
    local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(32, 64, 122); stroke.Parent = fab

    -- Letter M
    local label = Instance.new("TextLabel")
    label.Name = "Glyph"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = "M"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Parent = fab

    -- Invisible button on top
    local click = Instance.new("TextButton")
    click.BackgroundTransparency = 1
    click.Size = UDim2.fromScale(1, 1)
    click.Text = ""
    click.Parent = fab

    local function open()
        -- Close other UIs first
        UIBus:Fire("Magnets")
        panel.Visible = true
        player:SetAttribute("UILocked", true)
        local SetUILockState = RS:FindFirstChild("SetUILockState")
        if SetUILockState then SetUILockState:FireServer(true) end
    end

    local function close()
        panel.Visible = false
        player:SetAttribute("UILocked", false)
    end

    click.MouseButton1Click:Connect(function()
        if panel.Visible then close() else open() end
    end)

    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.M then
            if panel.Visible then close() else open() end
        end
    end)
end

-- Close when other panels open
UIBus.Event:Connect(function(who)
    if who ~= "Magnets" then
        panel.Visible = false
    end
end)
