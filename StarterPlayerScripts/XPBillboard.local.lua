-- XPBillboard.local.lua
-- World-space XP bar under player. Shows for 3 seconds after XP gain.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local XPUpdateRE = RS:WaitForChild("XPUpdate")

-- === TUNING ==========================================================
local OFFSET_Y = -3.9
local BAR_WIDTH = 220
local TRACK_TRANSPARENCY = 0.65
local SHOW_SECONDS = 3.0 -- was ~1.6, now 3s

-- === CLEANUP =========================================================
local function nukeLegacyXPUI()
	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg then
		for _, gui in ipairs(pg:GetChildren()) do
			if gui:IsA("ScreenGui") and (string.find(gui.Name:lower(), "xp") or gui:FindFirstChild("XPToast", true)) then
				gui:Destroy()
			end
		end
	end
	local char = LocalPlayer.Character
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BillboardGui") and part.Name ~= "XPBillboard" then
				if part:FindFirstChild("BarBG", true) then
					part:Destroy()
				end
			end
		end
	end
end
nukeLegacyXPUI()

-- === BUILD ===========================================================
local function ensureBillboard(char: Model)
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local bb = hrp:FindFirstChild("XPBillboard")
	if bb then
		bb.StudsOffsetWorldSpace = Vector3.new(0, OFFSET_Y, 0)
		return bb
	end

	bb = Instance.new("BillboardGui")
	bb.Name = "XPBillboard"
	bb.Adornee = hrp
	bb.AlwaysOnTop = true
	bb.MaxDistance = 180
	bb.Size = UDim2.fromOffset(BAR_WIDTH + 80, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(0, OFFSET_Y, 0)
	bb.Enabled = false
	bb.Parent = hrp

	local root = Instance.new("Frame")
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1,1)
	root.Parent = bb

	local barBG = Instance.new("Frame")
	barBG.Name = "BarBG"
	barBG.AnchorPoint = Vector2.new(0, 0.5)
	barBG.Position = UDim2.fromOffset(0, 12)
	barBG.Size = UDim2.fromOffset(BAR_WIDTH, 8)
	barBG.BackgroundColor3 = Color3.new(0,0,0)
	barBG.BackgroundTransparency = TRACK_TRANSPARENCY
	barBG.Parent = root
	local bgc = Instance.new("UICorner"); bgc.CornerRadius = UDim.new(0,4); bgc.Parent = barBG

	local bar = Instance.new("Frame")
	bar.Name = "Fill"
	bar.Size = UDim2.fromScale(0, 1)
	bar.BackgroundColor3 = Color3.new(1,1,1)
	bar.Parent = barBG
	local fgc = Instance.new("UICorner"); fgc.CornerRadius = UDim.new(0,4); fgc.Parent = bar

	local gain = Instance.new("TextLabel")
	gain.Name = "Gain"
	gain.BackgroundTransparency = 1
	gain.AnchorPoint = Vector2.new(0, 0.5)
	gain.Position = UDim2.fromOffset(BAR_WIDTH + 8, 12)
	gain.Size = UDim2.fromOffset(70, 18)
	gain.TextScaled = true
	gain.Font = Enum.Font.Gotham
	gain.TextColor3 = Color3.new(1,1,1)
	gain.TextXAlignment = Enum.TextXAlignment.Left
	gain.Text = "+0 XP"
	gain.Parent = root

	local lvl = Instance.new("TextLabel")
	lvl.Name = "Level"
	lvl.BackgroundTransparency = 1
	lvl.AnchorPoint = Vector2.new(0, 0)
	lvl.Position = UDim2.fromOffset(0, 22)
	lvl.Size = UDim2.fromOffset(BAR_WIDTH, 14)
	lvl.TextScaled = true
	lvl.Font = Enum.Font.GothamMedium
	lvl.TextColor3 = Color3.fromRGB(235,235,235)
	lvl.TextXAlignment = Enum.TextXAlignment.Center
	lvl.Text = "Lv 1"
	lvl.Parent = root

	return bb
end

local currentBB: BillboardGui? = nil
local function bindChar(char)
	currentBB = ensureBillboard(char)
	nukeLegacyXPUI()
end
Players.LocalPlayer.CharacterAdded:Connect(bindChar)
if Players.LocalPlayer.Character then bindChar(Players.LocalPlayer.Character) end

-- === DRIVE ===========================================================
local function showProgress(bb: BillboardGui, level: number, xp: number, need: number, delta: number)
	if not bb or (delta or 0) <= 0 then return end
	nukeLegacyXPUI()

	local barBG = bb:FindFirstChild("BarBG", true) :: Frame
	local bar = barBG and barBG:FindFirstChild("Fill") :: Frame
	local gain = bb:FindFirstChild("Gain", true) :: TextLabel
	local lvl  = bb:FindFirstChild("Level", true) :: TextLabel
	if not (bar and gain and lvl) then return end

	lvl.Text = ("Lv %d"):format(level)
	gain.Text = ("+%d XP"):format(math.max(0, math.floor(delta or 0)))

	local t = 0
	if need and need > 0 then t = math.clamp((xp or 0) / need, 0, 1) end
	bar:TweenSize(UDim2.fromScale(t, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)

	-- Show for 3 seconds (resets if new gain arrives)
	bb.Enabled = true
	task.spawn(function()
		local id = os.clock()
		bb:SetAttribute("LastShow", id)
		task.wait(SHOW_SECONDS)
		if bb:GetAttribute("LastShow") == id then
			bb.Enabled = false
		end
	end)
end

XPUpdateRE.OnClientEvent:Connect(function(payload)
	if not payload then return end
	local level = tonumber(payload.level) or 1
	local xp    = tonumber(payload.xp) or 0
	local need  = tonumber(payload.need) or 1
	local delta = tonumber(payload.delta) or 0

	if not currentBB or not currentBB.Parent then
		if LocalPlayer.Character then currentBB = ensureBillboard(LocalPlayer.Character) end
	end
	showProgress(currentBB, level, xp, need, delta)
end)
