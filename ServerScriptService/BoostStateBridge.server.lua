-- ServerScriptService/BoostStateBridge.server.lua
-- Provides initial server-luck state to clients on demand via RF and fires BoostChanged on join.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Boosts = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Boosts"))

-- Ensure the shared RemoteEvent exists (Boosts module should also create this)
local function ensureRE(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then return r end
	if r then r:Destroy() end
	r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = ReplicatedStorage
	return r
end

local function ensureRF(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteFunction") then return r end
	if r then r:Destroy() end
	r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = ReplicatedStorage
	return r
end

local BoostChanged = ensureRE("BoostChanged")
local GetServerLuckState = ensureRF("GetServerLuckState")

-- Answer initial state queries from clients
GetServerLuckState.OnServerInvoke = function(plr)
	local state = Boosts.GetServerLuck()
	local remaining = Boosts.GetServerLuckRemaining()
	return {
		active = (state and state.mult or 1) > 1 and remaining > 0,
		mult = state and state.mult or 1,
		remaining = remaining
	}
end

-- Also push state to a player when they join (optional convenience)
Players.PlayerAdded:Connect(function(plr)
	local state = Boosts.GetServerLuck()
	local remaining = Boosts.GetServerLuckRemaining()
	if (state and state.mult or 1) > 1 and remaining > 0 then
		BoostChanged:FireClient(plr, { type = "server_luck", mult = state.mult or 1, remaining = remaining })
	end
end)

print("[BoostStateBridge] Ready (GetServerLuckState RF online).")
