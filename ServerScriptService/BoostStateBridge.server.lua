-- ServerScriptService/BoostStateBridge.server.lua
-- Provides initial server-luck state and actively broadcasts transitions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Boosts = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Boosts"))

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

GetServerLuckState.OnServerInvoke = function(plr)
	local state = Boosts.GetServerLuck()
	local remaining = Boosts.GetServerLuckRemaining()
	return {
		active = (state and state.mult or 1) > 1 and remaining > 0,
		mult = state and state.mult or 1,
		remaining = remaining
	}
end

-- Push state to joiners if active
Players.PlayerAdded:Connect(function(plr)
	local state = Boosts.GetServerLuck()
	local rem = Boosts.GetServerLuckRemaining()
	if (state and state.mult or 1) > 1 and rem > 0 then
		BoostChanged:FireClient(plr, { type = "server_luck", mult = state.mult or 1, remaining = rem })
	end
end)

-- Monitor transitions (inactive -> active) and (active -> inactive)
task.spawn(function()
	local lastActive = false
	local lastMult = 1
	while true do
		task.wait(0.5)
		local st = Boosts.GetServerLuck()
		local rem = Boosts.GetServerLuckRemaining()
		local active = (st and st.mult or 1) > 1 and rem > 0
		local mult = st and st.mult or 1

		if active and (not lastActive or mult ~= lastMult) then
			-- Became active OR multiplier changed: broadcast start
			BoostChanged:FireAllClients({ type = "server_luck", mult = mult, remaining = rem })
		elseif (not active) and lastActive then
			-- Became inactive: broadcast stop
			BoostChanged:FireAllClients({ type = "server_luck", mult = 1, remaining = 0 })
		end

		lastActive = active
		lastMult = mult
	end
end)

print("[BoostStateBridge] Ready (GetServerLuckState + transition broadcaster).")
