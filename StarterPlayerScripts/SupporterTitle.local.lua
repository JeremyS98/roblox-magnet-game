-- SupporterTitle.local.lua
-- Shows a small "SUPPORTER" tag above the player's head if they own the Supporter gamepass.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local function ensureTag(char)
	-- Remove any previous tags
	for _, bb in ipairs(char:GetDescendants()) do
		if bb:IsA("BillboardGui") and bb.Name == "SupporterTag" then
			bb:Destroy()
		end
	end

	-- Check ownership from server
	local owns = false
	local rf = RS:FindFirstChild("CheckSupporter")
	if rf then
		pcall(function()
			owns = rf:InvokeServer() == true
		end)
	end
	if not owns then return end

	-- Create a simple tag
	local head = char:FindFirstChild("Head")
	if not head then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "SupporterTag"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, 0, 0, 0)
	bb.ExtentsOffset = Vector3.new(0, 2.5, 0)
	bb.Parent = head

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(140, 28)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
	frame.Parent = bb
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 12); c.Parent = frame
		local s = Instance.new("UIStroke"); s.Thickness = 1.5; s.Parent = frame
	end

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1,1)
	label.Text = "SUPPORTER"
	label.TextScaled = true
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.GothamBold
	label.Parent = frame
end

local function onCharacterAdded(char)
	-- Wait for head then try to attach
	char:WaitForChild("Head", 8)
	ensureTag(char)
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
