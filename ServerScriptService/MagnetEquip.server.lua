-- ServerScriptService/MagnetEquip.server.lua
-- Exposes remotes to get catalog and equip a magnet. Persists EquippedMagnetId on the player.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Magnets = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Magnets"))

-- Utilities to ensure remotes
local function ensureRF(name)
	local obj = ReplicatedStorage:FindFirstChild(name)
	if obj and obj:IsA("RemoteFunction") then return obj end
	if obj then obj:Destroy() end
	obj = Instance.new("RemoteFunction")
	obj.Name = name
	obj.Parent = ReplicatedStorage
	return obj
end

local GetMagnetsRF = ensureRF("GetMagnets")
local EquipMagnetRF = ensureRF("EquipMagnet")

-- Initialize EquippedMagnetId on join if missing
Players.PlayerAdded:Connect(function(plr)
	if plr:GetAttribute("EquippedMagnetId") == nil then
		plr:SetAttribute("EquippedMagnetId", "starter_basic")
	end
end)

-- Return catalog + equipped id (+ stats convenience if available)
GetMagnetsRF.OnServerInvoke = function(plr)
	local equipped = plr:GetAttribute("EquippedMagnetId") or "starter_basic"
	local entry = Magnets.ById(equipped)
	return {
		enabled = Magnets.enabled == true,
		catalog = Magnets.GetCatalog(),
		equipped = equipped,
		stats = entry and entry.stats or nil,
	}
end

-- Equip by id (no validation beyond existence for now)
EquipMagnetRF.OnServerInvoke = function(plr, id)
	local entry = Magnets.ById(id)
	if not entry then
		return { ok = false, error = "unknown_id" }
	end
	plr:SetAttribute("EquippedMagnetId", id)
	return { ok = true, equipped = id, stats = entry.stats }
end
