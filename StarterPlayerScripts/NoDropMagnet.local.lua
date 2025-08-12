-- NoDropMagnet.local.lua
-- Ensures the "Magnet" tool cannot be dropped (Backspace/drag). Also fixes future copies.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function lock(tool)
	if tool and tool:IsA("Tool") and tool.Name == "Magnet" then
		tool.CanBeDropped = false
	end
end

local function scan()
	-- Backpack
	for _,t in ipairs(player.Backpack:GetChildren()) do lock(t) end
	-- Equipped
	local char = player.Character
	if char then
		for _,t in ipairs(char:GetChildren()) do lock(t) end
	end
end

player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(lock)
	task.defer(scan)
end)

player.Backpack.ChildAdded:Connect(lock)
task.defer(scan)
