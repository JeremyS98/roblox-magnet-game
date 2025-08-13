local ReplicatedStorage = game:GetService("ReplicatedStorage")

local openReel = ReplicatedStorage:WaitForChild("OpenReel", 5)
local flagsFolder = ReplicatedStorage:WaitForChild("FeatureFlags", 5)
local reelV2 = flagsFolder and flagsFolder:FindFirstChild("ReelV2Enabled")

local function pickStatsFromCatalog(catalog, equippedId)
	if not catalog or not equippedId then return nil end

	-- Case 1: catalog is a dictionary keyed by id
	if typeof(catalog) == "table" and catalog[equippedId] then
		local entry = catalog[equippedId]
		if typeof(entry) == "table" then
			return entry.stats or entry  -- either nested stats or the entry *is* the stats
		end
	end

	-- Case 2: catalog is an array of entries { id="...", stats={...} }
	if typeof(catalog) == "table" then
		for _, entry in ipairs(catalog) do
			if typeof(entry) == "table" and entry.id == equippedId then
				return entry.stats or entry
			end
		end
	end
	return nil
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

local function onOpenReel(...)
	if not reelV2 or not reelV2.Value then return end
	local getMagnets = ReplicatedStorage:FindFirstChild("GetMagnets")
	if not getMagnets or not getMagnets:IsA("RemoteFunction") then
		warn("[ReelV2Logger] GetMagnets RemoteFunction not found")
		return
	end
	local data = getMagnets:InvokeServer()
	local equippedId = data and data.equipped
	local stats = data and (data.stats or pickStatsFromCatalog(data.catalog, equippedId))
	print(string.format("[ReelV2] Equipped %s %s", tostring(equippedId), stringify(stats)))
end

if openReel then
	openReel.OnClientEvent:Connect(onOpenReel)
else
	warn("[ReelV2Logger] OpenReel RemoteEvent not found")
end
