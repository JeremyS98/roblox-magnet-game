-- SupporterBridge.server.lua
-- Exposes a RemoteFunction "CheckSupporter" that returns whether a user owns the Supporter pass.

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local CheckSupporter = RS:FindFirstChild("CheckSupporter")
if not CheckSupporter then
	CheckSupporter = Instance.new("RemoteFunction")
	CheckSupporter.Name = "CheckSupporter"
	CheckSupporter.Parent = RS
end

-- Robust require of Modules/GamepassService
local GamepassService
local ok, mod = pcall(function()
	local Modules = SSS:FindFirstChild("Modules")
	if Modules then
		local inst = Modules:FindFirstChild("GamepassService") or Modules:FindFirstChild("GamepassService.lua")
		if inst then return require(inst) end
	end
	return nil
end)
if ok then GamepassService = mod end

CheckSupporter.OnServerInvoke = function(plr)
	if GamepassService and GamepassService.HasSupporter then
		return GamepassService.HasSupporter(plr.UserId) == true
	end
	return false
end
