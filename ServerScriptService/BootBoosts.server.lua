-- BoostsBridge.server.lua
-- Exposes server-luck boost state to clients via a RemoteFunction.
-- Depends on Modules/Boosts (already creates BoostChanged RemoteEvent).

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

-- Ensure RemoteFunction
local GetBoostState = RS:FindFirstChild("GetBoostState")
if not GetBoostState then
	GetBoostState = Instance.new("RemoteFunction")
	GetBoostState.Name = "GetBoostState"
	GetBoostState.Parent = RS
end

-- Try to require Boosts safely
local Boosts
local ok, mod = pcall(function()
	local Modules = SSS:FindFirstChild("Modules")
	if Modules then
		local inst = Modules:FindFirstChild("Boosts") or Modules:FindFirstChild("Boosts.lua")
		if inst then return require(inst) end
	end
	return nil
end)
if ok then Boosts = mod end

-- Implementation
GetBoostState.OnServerInvoke = function(plr)
	if Boosts then
		local s = Boosts.GetServerLuck()
		return { mult = s.mult or 1.0, remaining = Boosts.GetServerLuckRemaining() or 0, buyer = s.buyer or 0 }
	end
	return { mult = 1.0, remaining = 0, buyer = 0 }
end
