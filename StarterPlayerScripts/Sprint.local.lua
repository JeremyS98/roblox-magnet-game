-- Sprint.local.lua (StarterPlayerScripts)
-- Hold Left Shift to sprint at 1.5x your current base WalkSpeed.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local humanoid
local baseSpeed = 16
local sprinting = false
local MULT = 1.5

local function bindCharacter(char)
	humanoid = char:WaitForChild("Humanoid")
	baseSpeed = humanoid.WalkSpeed
	sprinting = false
	humanoid.Died:Connect(function() sprinting=false end)
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then bindCharacter(player.Character) end

local function setSprint(on)
	if not humanoid then return end
	if on and not sprinting then
		sprinting = true
		humanoid.WalkSpeed = math.floor(baseSpeed * MULT + 0.5)
	elseif (not on) and sprinting then
		sprinting = false
		humanoid.WalkSpeed = baseSpeed
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then setSprint(true) end
end)
UserInputService.InputEnded:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.LeftShift then setSprint(false) end
end)
