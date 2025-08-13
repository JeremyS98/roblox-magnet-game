local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local flags = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("FeatureFlags"))

local folder = ReplicatedStorage:FindFirstChild("FeatureFlags")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "FeatureFlags"
	folder.Parent = ReplicatedStorage
end

for k, v in pairs(flags) do
	local b = folder:FindFirstChild(k) or Instance.new("BoolValue")
	b.Name = k
	b.Value = (v == true)
	b.Parent = folder
end

print("[FeatureFlagsBridge] Mirrored feature flags to ReplicatedStorage.FeatureFlags")
