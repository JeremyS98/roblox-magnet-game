-- ServerScriptService/SupporterBridge.server.lua
-- Creates a world-anchored "Supporter" tag that sticks to the player's head (BillboardGui),
-- so it does NOT drift with the screen/camera. Safe to re-run on respawn.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Attempt to require optional modules safely so the script never hard-crashes
local Admins
do
	local ok, mod = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("Admins"))
	end)
	if ok then Admins = mod else warn("[SupporterBridge] Admins module missing or failed to load:", mod) end
end

local GamepassService
do
	local ok, mod = pcall(function()
		return require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("GamepassService"))
	end)
	if ok then GamepassService = mod else warn("[SupporterBridge] GamepassService module missing or failed to load:", mod) end
end

local function isSupporter(userId: number): boolean
	-- Admins count as supporters (for internal testing), otherwise check real gamepass if present
	if Admins and Admins.IsAdmin and Admins.IsAdmin(userId) then
		return true
	end
	if GamepassService and GamepassService.HasSupporter then
		local ok, res = pcall(function() return GamepassService.HasSupporter(userId) end)
		if ok and res == true then return true end
	end
	return false
end

local function removeBillboard(char: Model)
	if not char then return end
	for _, g in ipairs(char:GetChildren()) do
		if g:IsA("BillboardGui") and g.Name == "SupporterBillboard" then
			g:Destroy()
		end
	end
end

local function applyBillboard(player: Player, char: Model)
	if not char or not player then return end
	local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	if not head then return end

	-- Clean duplicates
	removeBillboard(char)

	-- Only add if the player is a supporter/admin
	if not isSupporter(player.UserId) then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "SupporterBillboard"
	bb.Adornee = head
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Size = UDim2.new(0, 140, 0, 22) -- width x height in pixels
	bb.StudsOffset = Vector3.new(0, 2.8, 0) -- lift above head; tweak if needed
	bb.MaxDistance = 150
	bb.Parent = char

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "SUPPORTER"
	label.TextColor3 = Color3.fromRGB(255, 235, 140) -- soft gold
	label.Parent = bb

	-- Outline for readability
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
end

local function onCharacter(player: Player, char: Model)
	-- Wait a short time to let the character parts exist
	task.spawn(function()
		for i = 1, 60 do
			if char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") then break end
			task.wait(0.05)
		end
		applyBillboard(player, char)
	end)
end

Players.PlayerAdded:Connect(function(plr: Player)
	plr.CharacterAdded:Connect(function(char: Model)
		onCharacter(plr, char)
	end)
	-- If character exists already (play solo), apply
	if plr.Character then
		onCharacter(plr, plr.Character)
	end
end)

Players.PlayerRemoving:Connect(function(plr: Player)
	local char = plr.Character
	if char then removeBillboard(char) end
end)

print("[SupporterBridge] Ready: Billboard tag will follow player head (world-anchored).")
