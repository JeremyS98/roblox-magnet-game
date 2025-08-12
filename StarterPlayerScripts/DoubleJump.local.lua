-- DoubleJump.local.lua
-- Second Space press mid-air adds HALF a normal jump's upward velocity at that moment.
-- Ground jump remains unchanged. Disabled while UI is locked.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local humanoid, hrp
local canDouble, usedDouble = false, false

local function getHalfJumpVelocity()
	if not humanoid then return 0 end
	local g = workspace.Gravity
	if humanoid.UseJumpPower then
		-- JumpPower is roughly the initial upward velocity
		return (humanoid.JumpPower or 50) * 0.5
	else
		-- Convert JumpHeight to velocity: v = sqrt(2*g*h)
		local h = humanoid.JumpHeight or 7.2
		return math.sqrt(2 * g * h) * 0.5
	end
end

local function onStateChanged(_, new)
	if new == Enum.HumanoidStateType.Landed then
		canDouble, usedDouble = false, false
	elseif new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
		canDouble = true
	end
end

local function bindCharacter(char)
	humanoid = char:WaitForChild("Humanoid")
	hrp = char:WaitForChild("HumanoidRootPart")
	canDouble, usedDouble = false, false
	humanoid.StateChanged:Connect(onStateChanged)
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then bindCharacter(player.Character) end

UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode ~= Enum.KeyCode.Space then return end
	if player:GetAttribute("UILocked") then return end -- blocked by UI
	if not humanoid or not hrp then return end

	local onGround = humanoid.FloorMaterial ~= Enum.Material.Air
	if onGround then
		-- normal first jump (Roblox handles); wait to arm double via state change
		return
	end

	-- explicit second press while airborne
	if canDouble and not usedDouble then
		usedDouble = true
		canDouble = false
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local extra = getHalfJumpVelocity()
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.max(0, v.Y) + extra, v.Z)
	end
end)
