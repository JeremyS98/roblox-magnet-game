-- ReelUI.local.lua (Fisch-style catch lines; same size; optional icon; no backgrounds)
-- Minigame logic mostly unchanged. Catch UI = two single-line centered labels + optional image above.
-- SFX stays in SearchingUI.local.lua.

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local OpenReelRE      = RS:WaitForChild("OpenReel")
local ReelResultRE    = RS:WaitForChild("ReelResult")
local CatchResultRE   = RS:WaitForChild("CatchResult")
local JournalDiscover = RS:WaitForChild("JournalDiscover")

local gui = script.Parent
gui.ResetOnSpawn = false
gui.Enabled = true

----------------------------------------------------------------
-- = Minigame UI
----------------------------------------------------------------
local frame = Instance.new("Frame")
frame.Name = "ReelRoot"
frame.Size = UDim2.fromScale(0.36, 0.62)
frame.Position = UDim2.fromScale(0.62, 0.19)
frame.BackgroundColor3 = Color3.fromRGB(18,18,20)
frame.BackgroundTransparency = 0.05
frame.Visible = false
frame.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,12); corner.Parent = frame
local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(0.75, 0.12)
title.Position = UDim2.fromScale(0.02, 0.02)
title.BackgroundTransparency = 1
title.Text = "Reel It In!"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.AnchorPoint = Vector2.new(1,0)
closeBtn.Size = UDim2.fromScale(0.1, 0.14)
closeBtn.Position = UDim2.fromScale(0.98, 0.02)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
closeBtn.Text = "X"
closeBtn.TextScaled = true
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Parent = frame
local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0,8); cCorner.Parent = closeBtn
local cStroke = Instance.new("UIStroke"); cStroke.Thickness = 1.5; cStroke.Parent = closeBtn

local track = Instance.new("Frame")
track.Name = "Track"
track.Size = UDim2.fromScale(0.28, 0.72)
track.Position = UDim2.fromScale(0.08, 0.2)
track.BackgroundColor3 = Color3.fromRGB(32,32,36)
track.Parent = frame
local tcorner = Instance.new("UICorner"); tcorner.CornerRadius = UDim.new(0,10); tcorner.Parent = track

local progBG = Instance.new("Frame")
progBG.Size = UDim2.fromScale(0.5, 0.12)
progBG.Position = UDim2.fromScale(0.42, 0.2)
progBG.BackgroundColor3 = Color3.fromRGB(32,32,36)
progBG.Parent = frame
local pcorner = Instance.new("UICorner"); pcorner.CornerRadius = UDim.new(0,8); pcorner.Parent = progBG
local progFill = Instance.new("Frame")
progFill.Size = UDim2.fromScale(0,1)
progFill.BackgroundColor3 = Color3.fromRGB(90,200,90)
progFill.Parent = progBG
local pfc = Instance.new("UICorner"); pfc.CornerRadius = UDim.new(0,8); pfc.Parent = progFill

local playerBar = Instance.new("Frame")
playerBar.Size = UDim2.fromScale(1, 0.20)
playerBar.Position = UDim2.fromScale(0, 0.7)
playerBar.BackgroundColor3 = Color3.fromRGB(70,140,220)
playerBar.BackgroundTransparency = 0.05
playerBar.Parent = track
local pbCorner = Instance.new("UICorner"); pbCorner.CornerRadius = UDim.new(0,8); pbCorner.Parent = playerBar

local fish = Instance.new("Frame")
fish.Size = UDim2.fromScale(1, 0.03)
fish.Position = UDim2.fromScale(0, 0.5)
fish.BackgroundColor3 = Color3.fromRGB(220,190,80)
fish.Parent = track
local fCorner = Instance.new("UICorner"); fCorner.CornerRadius = UDim.new(0,8); fCorner.Parent = fish

local info = Instance.new("TextLabel")
info.Size = UDim2.fromScale(1, 0.1)
info.Position = UDim2.fromScale(0, 0.9)
info.BackgroundTransparency = 1
info.Text = "Hold Mouse / Space / W to rise"
info.TextScaled = true
info.Font = Enum.Font.GothamMedium
info.TextColor3 = Color3.fromRGB(200,200,200)
info.Parent = frame

----------------------------------------------------------------
-- = Minigame state/logic
----------------------------------------------------------------
local active = false
local holding = false
local rarity = "Common"
local barRise, barFall, barHeight = 0.9, 0.8, 0.2
local fishBase, fishJitter, requiredFill = 0.6, 0.2, 2.5
local initialFillFrac, drainRate = 0.2, 0.5
local movementMode, sineSpeed = "target", 1.0

local playerY, fishY = 0.5, 0.5
local progressSec = 0
local fishTargetY = 0.5
local retargetTimer, burstTimer, sineT = 0, 0, 0
local armed = false

UserInputService.InputBegan:Connect(function(inp)
	if not active then return end
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.KeyCode == Enum.KeyCode.Space or inp.KeyCode == Enum.KeyCode.W then
		holding = true
	end
end)
UserInputService.InputEnded:Connect(function(inp)
	if not active then return end
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.KeyCode == Enum.KeyCode.Space or inp.KeyCode == Enum.KeyCode.W then
		holding = false
	end
end)

local function setVisible(v) frame.Visible = v end
local function clamp01(x) return (x<0 and 0) or (x>1 and 1) or x end
local function overlaps()
	local half = barHeight/2
	return (fishY >= (playerY - half)) and (fishY <= (playerY + half))
end

local savedWalk, savedJumpPower, savedUseJumpPower, savedJumpHeight
local function freezeCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	savedWalk = hum.WalkSpeed
	savedUseJumpPower = hum.UseJumpPower
	if hum.UseJumpPower then savedJumpPower = hum.JumpPower else savedJumpHeight = hum.JumpHeight end
	hum.WalkSpeed = 0
	if hum.UseJumpPower then hum.JumpPower = 0 else hum.JumpHeight = 0 end
	local sink = function() return Enum.ContextActionResult.Sink end
	ContextActionService:BindAction("ReelLock_Move", sink, false,
		Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight,
		Enum.PlayerActions.CharacterJump)
end
local function unfreezeCharacter()
	ContextActionService:UnbindAction("ReelLock_Move")
	local hum = (player.Character and player.Character:FindFirstChildOfClass("Humanoid"))
	if not hum then return end
	if savedWalk then hum.WalkSpeed = savedWalk end
	if savedUseJumpPower ~= nil then hum.UseJumpPower = savedUseJumpPower end
	if hum.UseJumpPower then if savedJumpPower then hum.JumpPower = savedJumpPower end
	else if savedJumpHeight then hum.JumpHeight = savedJumpHeight end end
end

local function endMinigame(success)
	active = false
	setVisible(false)
	player:SetAttribute("UILocked", false)
	unfreezeCharacter()
	ReelResultRE:FireServer({success = success, rarity = rarity})
end

closeBtn.MouseButton1Click:Connect(function()
	if active then endMinigame(false) end
end)

local function updateFish(dt)
	if movementMode == "sine" then
		sineT += dt * sineSpeed
		local a = 0.36
		fishY = 0.5 + a * math.sin(sineT)
		fishY += ((math.random()-0.5) * 2) * (fishJitter * 0.05) * dt
		fishY = clamp01(fishY)
	elseif movementMode == "hybrid" then
		sineT += dt * (sineSpeed * 1.2)
		local a = 0.42
		local baseY = 0.5 + a * math.sin(sineT)
		retargetTimer += dt; burstTimer += dt
		if burstTimer >= 1.8 then
			burstTimer = 0
			baseY = baseY + ((math.random()-0.5)*0.4)
		end
		local diff = baseY - fishY
		fishY += math.sign(diff) * fishBase * dt + ((math.random()-0.5) * 2) * (fishJitter * 0.15) * dt
		fishY = clamp01(fishY)
	else
		retargetTimer += dt; burstTimer += dt
		if burstTimer >= 2.2 then
			burstTimer = 0
			if fishY < 0.5 then fishTargetY = math.random(60, 92)/100 else fishTargetY = math.random(8, 40)/100 end
			retargetTimer = 0
		elseif retargetTimer >= 0.8 then
			retargetTimer = 0
			fishTargetY = math.random(8, 92)/100
		end
		local diff = fishTargetY - fishY
		local dir = (diff >= 0) and 1 or -1
		local speed = fishBase + (math.abs(diff) * 0.5)
		local rand = (math.random() - 0.5) * 2 * fishJitter
		fishY = fishY + (dir * speed * dt) + (rand * dt)
		if fishY < 0 then fishY = 0; fishTargetY = math.random(30, 92)/100 end
		if fishY > 1 then fishY = 1; fishTargetY = math.random(8, 70)/100 end
	end
end

RunService.RenderStepped:Connect(function(dt)
	if not active then return end
	if holding then playerY -= (barRise * dt) else playerY += (barFall * dt) end
	playerY = clamp01(playerY)
	updateFish(dt)

	if overlaps() then
		progressSec = math.min(requiredFill, progressSec + dt)
		armed = true
	else
		if armed then
			progressSec = math.max(0, progressSec - (drainRate * dt))
		end
	end

	playerBar.Position = UDim2.fromScale(0, playerY - barHeight/2)
	playerBar.Size     = UDim2.fromScale(1, barHeight)
	fish.Position      = UDim2.fromScale(0, fishY - 0.015)
	progFill.Size      = UDim2.fromScale(math.clamp(progressSec / requiredFill, 0, 1), 1)

	if progressSec >= requiredFill then
		endMinigame(true)
	elseif progressSec <= 0 and armed then
		endMinigame(false)
	end
end)

OpenReelRE.OnClientEvent:Connect(function(cfg)
	if type(cfg) ~= "table" then return end
	rarity          = cfg.rarity or "Common"
	barRise         = tonumber(cfg.barRise) or 0.9
	barFall         = tonumber(cfg.barFall) or 0.8
	barHeight       = tonumber(cfg.barHeight) or 0.2
	fishBase        = tonumber(cfg.fishBase) or 0.6
	fishJitter      = tonumber(cfg.fishJitter) or 0.2
	requiredFill    = tonumber(cfg.requiredFill) or 2.5
	initialFillFrac = tonumber(cfg.initialFillFrac) or 0.2
	drainRate       = tonumber(cfg.drainRate) or 0.5
	movementMode    = tostring(cfg.movementMode or "target")
	sineSpeed       = tonumber(cfg.sineSpeed) or 1.0

	armed = false
	progressSec = math.clamp(initialFillFrac * requiredFill, 0, requiredFill)

	-- start slightly lower and ensure first motion is downward
	playerY = 0.45
	fishY = 0.5
	holding = false

	fishTargetY, retargetTimer, burstTimer, sineT = 0.5, 0, 0, 0
	progFill.Size = UDim2.fromScale(progressSec/requiredFill,1)

	player:SetAttribute("UILocked", true)
	freezeCharacter()
	frame.Visible = true
	active = true
end)

----------------------------------------------------------------
-- Fisch-style catch lines (no backgrounds) + optional icon
----------------------------------------------------------------
local RARITY_HEX = {
	Common    = "#EBEBEB",
	Rare      = "#5A96FF",
	Epic      = "#B46EFF",
	Legendary = "#FFD25A",
}
local WHITE_HEX = "#FFFFFF"
local LIGHT_GRAY_HEX = "#DDDDDD"

local FIXED_TEXT_SIZE = 30

local function makeLine(name, yScale)
	local lbl = Instance.new("TextLabel")
	lbl.Name = name
	lbl.AnchorPoint = Vector2.new(0.5, 0)
	lbl.Position = UDim2.fromScale(0.5, yScale)
	lbl.Size = UDim2.fromScale(0.96, 0.07)
	lbl.BackgroundTransparency = 1
	lbl.RichText = true
	lbl.TextWrapped = false
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = FIXED_TEXT_SIZE
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Visible = false
	lbl.ZIndex = 10060
	lbl.Parent = gui
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(0,0,0); stroke.Parent = lbl
	return lbl
end

local catchLine   = makeLine("CatchLine",   0.10)
local journalLine = makeLine("JournalLine", 0.15)

local icon = Instance.new("ImageLabel")
icon.Name = "CatchIcon"
icon.AnchorPoint = Vector2.new(0.5, 1)
icon.Position = UDim2.fromScale(0.5, 0.08)
icon.Size = UDim2.fromOffset(96, 96)
icon.BackgroundTransparency = 1
icon.ImageTransparency = 0
icon.Visible = false
icon.ZIndex = 10059
icon.Parent = gui
local uiGrad = Instance.new("UIGradient"); uiGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
}; uiGrad.Parent = icon

local SHOW_TIME = 3.0
local function showFor3s(lbl)
	lbl.TextTransparency = 0     -- FORCE fully visible
	lbl.Visible = true
	task.delay(SHOW_TIME, function()
		if lbl and lbl.Parent then lbl.Visible = false end
	end)
end
local function hideIconLater()
	icon.Visible = true
	task.delay(SHOW_TIME, function()
		if icon and icon.Parent then icon.Visible = false end
	end)
end

-- RichText builders
local function catchText(itemName, rarityName, pounds2dp)
	local col = RARITY_HEX[rarityName] or WHITE_HEX
	return string.format(
		'<font color="%s">You just caught a </font><font color="%s">%s</font><font color="%s"> at </font><font color="%s">%.2flb</font><font color="%s">!</font>',
		WHITE_HEX, col, itemName, WHITE_HEX, LIGHT_GRAY_HEX, pounds2dp, WHITE_HEX
	)
end
local function journalText(itemName, rarityName)
	local col = RARITY_HEX[rarityName] or WHITE_HEX
	return string.format(
		'<font color="%s">Journal: </font><font color="%s">New Item</font><font color="%s">! %s</font>',
		WHITE_HEX, col, WHITE_HEX, itemName or "Unknown"
	)
end

-- quick de-dupe guard
local lastKey, lastT = nil, 0
local function shouldShow(name)
	local now = os.clock()
	if name == lastKey and (now - lastT) <= 0.4 then return false end
	lastKey, lastT = name, now
	return true
end

-- Catch popup
local pending = { name=nil, rarity="Common", t=0 }
CatchResultRE.OnClientEvent:Connect(function(name, rarityGot, kg, iconId)
	if not shouldShow(name) then return end
	local lb = math.floor((kg or 0)*2.20462*100 + 0.5)/100
	pending = { name = name, rarity = tostring(rarityGot or "Common"), t = os.clock() }

	catchLine.Text = catchText(name, pending.rarity, lb)
	showFor3s(catchLine)

	if iconId and tostring(iconId) ~= "" then
		icon.Image = "rbxassetid://"..tostring(iconId)
		hideIconLater()
	else
		icon.Visible = false
	end
	-- DO NOT hide journalLine here anymore
end)

-- Journal popup (always show when server announces discovery)
JournalDiscover.OnClientEvent:Connect(function(info)
	local iname = type(info)=="table" and info.name or nil
	local irar  = type(info)=="table" and info.rarity or "Common"
	if not iname then return end
	journalLine.Text = journalText(iname, irar)
	showFor3s(journalLine)
end)

----------------------------------------------------------------
-- Cleanup legacy toasts
----------------------------------------------------------------
for _,g in ipairs(gui:GetChildren()) do
	if g.Name == "CatchToast" or g.Name == "JournalToast" or g.Name == "CatchOneLine" or g.Name == "CatchMessage" then
		g:Destroy()
	end
end
