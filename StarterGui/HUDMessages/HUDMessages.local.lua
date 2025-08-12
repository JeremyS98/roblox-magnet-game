-- HUDMessages.local.lua (Backpack Full + Sell coins toast, text-only, no background)

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameMessageRE   = RS:WaitForChild("GameMessage")   -- "BACKPACK_FULL"
local SellAllResultRE = RS:WaitForChild("SellAllResult") -- number of coins from sell

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- Root gui
local gui = Instance.new("ScreenGui")
gui.Name = "HUDMessages"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

-- Label style: matches no-background catch/journal lines
local LABEL_SIZE = UDim2.fromScale(0.60, 0.06)
local LABEL_POS  = UDim2.fromScale(0.20, 0.20) -- sits below catch/journal lines
local WHITE = Color3.fromRGB(255,255,255)
local BLACK = Color3.fromRGB(0,0,0)
local VISIBLE_SECONDS = 3.0

local function ensureLabel(): TextLabel
	local label = gui:FindFirstChild("MsgLine") :: TextLabel
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "MsgLine"
		label.BackgroundTransparency = 1
		label.Size = LABEL_SIZE
		label.Position = LABEL_POS
		label.TextScaled = true
		label.RichText = true
		label.TextColor3 = WHITE
		label.TextTransparency = 1
		label.Visible = false
		label.ZIndex = 300
		label.Parent = gui

		local s = Instance.new("UIStroke")
		s.Thickness = 1.5
		s.Color = BLACK
		s.Parent = label
	end
	return label
end

local function show(text: string)
	local label = ensureLabel()
	label.Text = text
	label.Visible = true
	for i = 1, 10 do label.TextTransparency = 1 - i/10; task.wait(0.02) end
	task.delay(VISIBLE_SECONDS - 0.4, function()
		for i = 1, 10 do label.TextTransparency = i/10; task.wait(0.02) end
		label.Visible = false
	end)
end

-- Server messages
GameMessageRE.OnClientEvent:Connect(function(kind)
	if kind == "BACKPACK_FULL" then
		show("Backpack full! Sell or delete items.")
	end
end)

SellAllResultRE.OnClientEvent:Connect(function(totalCoins)
	local n = tonumber(totalCoins) or 0
	show(("You earned %d coins."):format(n))
end)
