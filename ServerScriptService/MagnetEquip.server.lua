-- ServerScriptService/MagnetEquip.server.lua
-- Backend for magnet inventory/equip (no gameplay effect yet).
-- Provides remotes to read catalog and set EquippedMagnetId in player data.
-- Safe to run with FeatureFlags.MagnetsEnabled=false (no behavior change).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local FeatureFlags = require(SSS:WaitForChild("Modules"):WaitForChild("FeatureFlags"))
local MagnetCatalog = require(SSS:WaitForChild("Modules"):WaitForChild("MagnetCatalog"))

local function ensureRE(n)
	local r = RS:FindFirstChild(n)
	if r and r:IsA("RemoteEvent") then return r end
	if r then r:Destroy() end
	r = Instance.new("RemoteEvent"); r.Name = n; r.Parent = RS
	return r
end
local function ensureRF(n)
	local r = RS:FindFirstChild(n)
	if r and r:IsA("RemoteFunction") then return r end
	if r then r:Destroy() end
	r = Instance.new("RemoteFunction"); r.Name = n; r.Parent = RS
	return r
end

local GetMagnetsRF   = ensureRF("GetMagnets")
local EquipMagnetRF  = ensureRF("EquipMagnet")

-- You may already be persisting EquippedMagnetId in MagnetGame.server.lua snapshot/load.
-- We simply read/write player attribute here for now; the main save loop will capture it.

local function getEquippedId(plr)
	return plr:GetAttribute("EquippedMagnetId")
end

local function setEquippedId(plr, id)
	plr:SetAttribute("EquippedMagnetId", id)
end

-- Remote implementations
GetMagnetsRF.OnServerInvoke = function(plr)
	-- Return catalog and the player's current equipped id
	local cat = MagnetCatalog.ALL()
	local equipped = getEquippedId(plr) or MagnetCatalog.DEFAULT_ID()
	return { catalog = cat, equipped = equipped, enabled = FeatureFlags.MagnetsEnabled == true }
end

EquipMagnetRF.OnServerInvoke = function(plr, magnetId)
	if type(magnetId) ~= "string" then return { ok = false, err = "bad_id" } end
	local def = MagnetCatalog.GET(magnetId)
	if not def then return { ok = false, err = "unknown" } end

	-- For now, no ownership gating—everyone "owns" the starter set.
	setEquippedId(plr, magnetId)

	-- No gameplay effect yet; we only store. When MagnetsEnabled is true, game will start reading stats.
	return { ok = true, equipped = magnetId, stats = def.stats or {} }
end

-- Ensure every joining player has a default id set (non-destructive)
local defaultId = MagnetCatalog.DEFAULT_ID()
Players.PlayerAdded:Connect(function(plr)
	if not plr:GetAttribute("EquippedMagnetId") then
		plr:SetAttribute("EquippedMagnetId", defaultId)
	end
end)
