-- TopShop.local.lua
-- Renders a small "Shop" button at the top-center. Clicking opens a Premium Shop modal with purchase buttons.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TopShop"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Top center button
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundTransparency = 1
topBar.Size = UDim2.fromScale(1, 0.08)
topBar.Position = UDim2.fromScale(0, 0)
topBar.Parent = gui

local shopBtn = Instance.new("TextButton")
shopBtn.Name = "ShopBtn"
shopBtn.AnchorPoint = Vector2.new(0.5, 0)
shopBtn.Size = UDim2.fromScale(0.10, 0.65)
shopBtn.Position = UDim2.fromScale(0.5, 0.2)
shopBtn.Text = "Shop"
shopBtn.TextScaled = true
shopBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 150)
shopBtn.TextColor3 = Color3.new(1,1,1)
shopBtn.Parent = topBar
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = shopBtn
    local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Parent = shopBtn
end

-- Modal (hidden by default)
local modal = Instance.new("Frame")
modal.Name = "PremiumShop"
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Size = UDim2.fromScale(0.46, 0.48)
modal.Position = UDim2.fromScale(0.5, 0.5)
modal.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
modal.Visible = false
modal.Parent = gui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = modal
    local s = Instance.new("UIStroke"); s.Thickness = 2; s.Parent = modal
end

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.fromScale(1, 0.18)
title.Position = UDim2.fromScale(0, 0)
title.Text = "✨ Premium Shop"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255, 240, 160)
title.Font = Enum.Font.GothamBold
title.Parent = modal

local close = Instance.new("TextButton")
close.Size = UDim2.fromScale(0.1, 0.16)
close.Position = UDim2.fromScale(0.9, 0.02)
close.Text = "X"
close.TextScaled = true
close.TextColor3 = Color3.new(1,1,1)
close.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
close.Parent = modal
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = close
end

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromScale(0.46, 0.28)
grid.CellPadding = UDim2.fromScale(0.06, 0.06)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.VerticalAlignment = Enum.VerticalAlignment.Center
grid.FillDirectionMaxCells = 2

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Size = UDim2.fromScale(0.94, 0.70)
content.Position = UDim2.fromScale(0.03, 0.22)
content.Parent = modal
grid.Parent = content

local function makeButton(label)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromScale(1,1)
    b.Text = label
    b.TextScaled = true
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(50, 90, 140)
    b.AutoButtonColor = true
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = b
    local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Parent = b
    b.Parent = content
    return b
end

local btnSellAnywhere = makeButton("Sell Anywhere (Pass)")
local btnDoubleXP    = makeButton("Double XP (Pass)")
local btnSupporter   = makeButton("Supporter (Pass)")
local btnLuck        = makeButton("Luck x2 • 15m (Product)")

-- Hook purchase actions
local GetGamepassIdsRF = RS:FindFirstChild("GetGamepassIds")
local GetProductIdsRF  = RS:FindFirstChild("GetProductIds")

local PASS = {}
local PROD = {}

pcall(function() if GetGamepassIdsRF then PASS = GetGamepassIdsRF:InvokeServer() end end)
pcall(function() if GetProductIdsRF  then PROD = GetProductIdsRF:InvokeServer()  end end)

local function promptPass(id)
    if id and id > 0 then
        MarketplaceService:PromptGamePassPurchase(player, id)
    end
end
local function promptProduct(id)
    if id and id > 0 then
        MarketplaceService:PromptProductPurchase(player, id)
    end
end

btnSellAnywhere.MouseButton1Click:Connect(function() promptPass(PASS.SELL_ANYWHERE) end)
btnDoubleXP.MouseButton1Click:Connect(function() promptPass(PASS.DOUBLE_XP) end)
btnSupporter.MouseButton1Click:Connect(function() promptPass(PASS.SUPPORTER) end)
btnLuck.MouseButton1Click:Connect(function() promptProduct(PROD.SERVER_LUCK_2X_15MIN) end)

-- Button wiring
shopBtn.MouseButton1Click:Connect(function()
    modal.Visible = not modal.Visible
end)
close.MouseButton1Click:Connect(function()
    modal.Visible = false
end)

-- Optional: close if player presses ESC or re-opens
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Escape and modal.Visible then
        modal.Visible = false
    end
end)
