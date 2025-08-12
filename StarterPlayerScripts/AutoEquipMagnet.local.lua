-- AutoEquipMagnet.local.lua
-- Auto-equips the "Magnet" tool on spawn.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function equip()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	-- wait a moment for tools to replicate into Backpack
	task.wait(0.1)
	local tool = player.Backpack:FindFirstChild("Magnet")
	if tool then
		hum:EquipTool(tool)
	end
end

player.CharacterAdded:Connect(function()
	task.defer(equip)
end)

if player.Character then
	task.defer(equip)
end
