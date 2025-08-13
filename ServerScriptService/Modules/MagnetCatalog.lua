-- ServerScriptService/Modules/MagnetCatalog.lua
-- Shadow Magnet Catalog (no gameplay effect yet)
-- Neutral baseline stats; later steps will apply these to gameplay when MagnetsEnabled is true.

local Catalog = {
	-- id must be unique string; displayName is shown to players later
	-- All stats neutral for now
	{ id = "basic",     displayName = "Basic Magnet",     rarity = "Common",    stats = { lure = 0, rarity = 0, control = 0, power = 0, stability = 0 } },
	{ id = "lucky",     displayName = "Lucky Magnet",     rarity = "Rare",      stats = { lure = 0, rarity = 0, control = 0, power = 0, stability = 0 } },
	{ id = "fast",      displayName = "Fast Magnet",      rarity = "Rare",      stats = { lure = 0, rarity = 0, control = 0, power = 0, stability = 0 } },
	{ id = "control",   displayName = "Control Magnet",   rarity = "Epic",      stats = { lure = 0, rarity = 0, control = 0, power = 0, stability = 0 } },
	{ id = "heavy",     displayName = "Heavy Magnet",     rarity = "Epic",      stats = { lure = 0, rarity = 0, control = 0, power = 0, stability = 0 } },
	{ id = "resilient", displayName = "Resilient Magnet", rarity = "Legendary", stats = { lure = 0, rarity = 0, control = 0, power = 0, stability = 0 } },
}

local DEFAULT_ID = "basic"

local Index = {}
for _, m in ipairs(Catalog) do
	Index[m.id] = m
end

local M = {}

function M.All()
	return Catalog
end

function M.DefaultId()
	return DEFAULT_ID
end

function M.Get(id)
	return Index[id]
end

function M.IsValid(id)
	return Index[id] ~= nil
end

return M
