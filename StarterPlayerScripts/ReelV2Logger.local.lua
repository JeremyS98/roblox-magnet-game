local ReplicatedStorage = game:GetService("ReplicatedStorage")

local openReel = ReplicatedStorage:WaitForChild("OpenReel", 5)
local flagsFolder = ReplicatedStorage:WaitForChild("FeatureFlags", 5)
local reelV2 = flagsFolder and flagsFolder:FindFirstChild("ReelV2Enabled")

local function onOpenReel(...)
	if not reelV2 or not reelV2.Value then return end
	local getMagnets = ReplicatedStorage:FindFirstChild("GetMagnets")
	if not getMagnets or not getMagnets:IsA("RemoteFunction") then
		warn("[ReelV2Logger] GetMagnets RemoteFunction not found")
		return
	end
	local data = getMagnets:InvokeServer()
	print("[ReelV2] Equipped", data and data.equipped, data and data.stats)
end

if openReel then
	openReel.OnClientEvent:Connect(onOpenReel)
else
	warn("[ReelV2Logger] OpenReel RemoteEvent not found")
end
