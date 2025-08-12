-- SearchingUI.local.lua (no background, supports string OR boolean protocol)
-- Server can send:
--   • strings: "searching" | "hit" | "clear"
--   • booleans: true (searching) | false (hit)
-- Also plays a distinct catch sound on CatchResult.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- Remotes
local SearchEvt    = RS:WaitForChild("SearchStatus")
local OpenReelRE   = RS:WaitForChild("OpenReel")
local ReelEndedRE  = RS:WaitForChild("ReelEnded")
local CatchResult  = RS:WaitForChild("CatchResult")

-- Nuke any previous copy
local old = pg:FindFirstChild("SearchingUI")
if old then old:Destroy() end

-- Root GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SearchingUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

-- "Searching for item..." (NO background)
local label = Instance.new("TextLabel")
label.Name = "SearchingLabel"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.fromScale(0.5, 0.25)
label.Size = UDim2.fromOffset(360, 40)
label.BackgroundTransparency = 1
label.BorderSizePixel = 0
label.TextScaled = true
label.Font = Enum.Font.GothamMedium
label.TextColor3 = Color3.fromRGB(235,235,235)
label.Text = "Searching for item"
label.ZIndex = 1001
label.Visible = false
label.Parent = gui
local searchStroke = Instance.new("UIStroke")
searchStroke.Thickness = 2
searchStroke.Color = Color3.fromRGB(0, 0, 0)
searchStroke.Parent = label


-- Big red "HIT!" (higher on the screen)
local hitLbl = Instance.new("TextLabel")
hitLbl.Name = "Hit"
hitLbl.AnchorPoint = Vector2.new(0.5, 0)
hitLbl.Position = UDim2.fromScale(0.5, 0.18)
hitLbl.Size = UDim2.fromOffset(360, 180)
hitLbl.BackgroundTransparency = 1
hitLbl.TextScaled = true
hitLbl.Font = Enum.Font.GothamBlack
hitLbl.Text = "HIT!"
hitLbl.TextColor3 = Color3.fromRGB(230, 40, 40)
hitLbl.TextStrokeTransparency = 0
hitLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
hitLbl.Visible = false
hitLbl.ZIndex = 1100
hitLbl.Parent = gui

-- SFX
local sfxHit = Instance.new("Sound")
sfxHit.Name = "SFX_Hit"
sfxHit.SoundId = "rbxassetid://133320007723815"   -- bite/HIT cue
sfxHit.Volume = 0.6
sfxHit.Parent = SoundService

local sfxCatch = Instance.new("Sound")
sfxCatch.Name = "SFX_Catch"
sfxCatch.SoundId = "rbxassetid://131666181254016" -- catch/reward cue
sfxCatch.Volume = 0.9
sfxCatch.Parent = SoundService

-- Animated dots for "Searching..."
local running = false
task.spawn(function()
	local dots = 0
	while gui.Parent do
		if running then
			dots = (dots + 1) % 4
			local suffix = (dots==0 and "") or (dots==1 and ".") or (dots==2 and "..") or "..."
			label.Text = "Searching for item"..suffix
		end
		task.wait(0.33)
	end
end)

local function hideAll()
	label.Visible = false
	hitLbl.Visible = false
	running = false
end

local function startSearching()
	running = true
	label.Text = "Searching for item"
	hitLbl.Visible = false
	label.Visible = true
end

local lastHitPlay = 0
local function showHit()
	running = false
	label.Visible = false
	hitLbl.Visible = true
	-- play once per bite
	local now = os.clock()
	if now - lastHitPlay > 0.25 then
		lastHitPlay = now
		task.spawn(function()
			if sfxHit.IsLoaded then sfxHit:Play() else sfxHit.Loaded:Wait(); sfxHit:Play() end
		end)
	end
	-- auto-hide after ~2s (minigame should open soon after)
	task.delay(2.0, function()
		if hitLbl and hitLbl.Parent then
			hitLbl.Visible = false
		end
	end)
end

-- Normalizer: accept both string and boolean protocols
local function normalizeState(state)
	if typeof(state) == "boolean" then
		return state and "searching" or "hit"
	end
	if state == "searching" or state == "hit" or state == "clear" then
		return state
	end
	return "clear"
end

-- Wiring
SearchEvt.OnClientEvent:Connect(function(state)
	state = normalizeState(state)
	if state == "searching" then
		startSearching()
	elseif state == "hit" then
		showHit()
	else
		hideAll()
	end
end)

OpenReelRE.OnClientEvent:Connect(hideAll)
ReelEndedRE.OnClientEvent:Connect(hideAll)

-- Distinct catch SFX (only when loot is actually awarded)
local lastCatchPlay = 0
CatchResult.OnClientEvent:Connect(function()
	local now = os.clock()
	if now - lastCatchPlay > 0.1 then
		lastCatchPlay = now
		if sfxCatch.IsLoaded then sfxCatch:Play() else sfxCatch.Loaded:Wait(); sfxCatch:Play() end
	end
end)
