-- OverheadLevels.local.lua
-- Softer, smaller "Level: X" above the Head (not camera-based).
-- Soft white text with subtle gray outline.

local Players = game:GetService("Players")

local SOFT_WHITE = Color3.fromRGB(235,235,235)
local OUTLINE_GRAY = Color3.fromRGB(120,120,120)

local function attachBillboard(char, levelValue)
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local bb = head:FindFirstChild("LevelBillboard")
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = "LevelBillboard"
		bb.Adornee = head
		bb.AlwaysOnTop = true
		bb.MaxDistance = 160
		bb.Size = UDim2.fromOffset(72, 18)         -- smaller
		bb.StudsOffsetWorldSpace = Vector3.new(0, 1.4, 0) -- a bit above head
		bb.Parent = head

		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.fromScale(1,1)
		tl.BackgroundTransparency = 1
		tl.TextScaled = true
		tl.Font = Enum.Font.GothamSemibold
		tl.TextColor3 = SOFT_WHITE
		tl.Parent = bb

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Color = OUTLINE_GRAY
		stroke.Parent = tl
	end

	local tl = bb:FindFirstChild("Text") :: TextLabel
	tl.Text = ("Level: %d"):format(levelValue.Value)
end

local function hookPlayer(plr)
	local function onCharacter(char)
		local levelVal
		local ls = plr:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Level") then
			levelVal = ls.Level
		else
			levelVal = Instance.new("IntValue")
			levelVal.Name = "LevelMirror"
			levelVal.Value = plr:GetAttribute("Level") or 1
			levelVal.Parent = char
			plr:GetAttributeChangedSignal("Level"):Connect(function()
				levelVal.Value = plr:GetAttribute("Level") or 1
			end)
		end

		attachBillboard(char, levelVal)
		levelVal:GetPropertyChangedSignal("Value"):Connect(function()
			attachBillboard(char, levelVal)
		end)
	end

	plr.CharacterAdded:Connect(onCharacter)
	if plr.Character then onCharacter(plr.Character) end
end

for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
Players.PlayerAdded:Connect(hookPlayer)
