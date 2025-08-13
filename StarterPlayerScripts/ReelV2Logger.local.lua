local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OpenReel = ReplicatedStorage:WaitForChild("OpenReel", 5)
local ReelEnded = ReplicatedStorage:FindFirstChild("ReelEnded")
local Flags = ReplicatedStorage:WaitForChild("FeatureFlags", 5)
local ReelV2Flag = Flags and Flags:FindFirstChild("ReelV2Enabled")

local function pickStatsFromCatalog(catalog, equippedId)
	if not catalog or not equippedId then return nil end

	-- Dictionary form: catalog[id] = { stats = {...} } or direct stats table
	if typeof(catalog) == "table" and catalog[equippedId] then
		local entry = catalog[equippedId]
		if typeof(entry) == "table" then
			return entry.stats or entry
		end
	end

	-- Array form: { {id="...", stats={...}}, ... }
	if typeof(catalog) == "table" then
		for _, entry in ipairs(catalog) do
			if typeof(entry) == "table" and entry.id == equippedId then
				return entry.stats or entry
			end
		end
	end
	return nil
end

local function normalizeStats(stats)
	-- Accept multiple key names and default to 1.0 (neutral) if missing or == 0
	local function val(x)
		if x == nil or x == 0 then return 1.0 end
		return x
	end
	return {
		lure      = val(stats and (stats.lure or stats.speed)),
		rarity    = val(stats and (stats.rarity or stats.luck)),
		control   = val(stats and (stats.control)),
		weight    = val(stats and (stats.weight or stats.maxWeight)),
		stability = val(stats and (stats.stability)),
	}
end

local function stringify(tbl)
	if typeof(tbl) ~= "table" then return tostring(tbl) end
	local parts = {}
	for k, v in pairs(tbl) do
		table.insert(parts, tostring(k) .. "=" .. tostring(v))
	end
	table.sort(parts)
	return "{ " .. table.concat(parts, ", ") .. " }"
end

local function getMagnetInfo()
	local rf = ReplicatedStorage:FindFirstChild("GetMagnets")
	if not rf or not rf:IsA("RemoteFunction") then
		return nil
	end
	local data = rf:InvokeServer()
	if not data then return nil end

	local equippedId = data.equipped
	local rawStats = data.stats or pickStatsFromCatalog(data.catalog, equippedId)
	local stats = normalizeStats(rawStats or {})

	return equippedId, stats
end

local function onOpenReel(...)
	if not ReelV2Flag or not ReelV2Flag.Value then return end
	local id, stats = getMagnetInfo()
	print(string.format("[ReelV2/start] Equipped %s %s", tostring(id), stringify(stats)))
end

local function onReelEnded(...)
	if not ReelV2Flag or not ReelV2Flag.Value then return end
	local id, stats = getMagnetInfo()
	print(string.format("[ReelV2/end] Equipped %s %s", tostring(id), stringify(stats)))
end

if OpenReel then
	OpenReel.OnClientEvent:Connect(onOpenReel)
else
	warn("[ReelV2Logger] OpenReel RemoteEvent not found")
end

if ReelEnded then
	ReelEnded.OnClientEvent:Connect(onReelEnded)
end
