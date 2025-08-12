-- Boosts.lua
-- Server-wide timed boosts (e.g., Double Server Luck).
-- Safe to require at startup; creates/fetches necessary RemoteEvents.
-- No gameplay effect by itself until other scripts read the multiplier.

local RS = game:GetService("ReplicatedStorage")

-- Ensure RemoteEvent exists for client HUD to listen later
local BoostChanged = RS:FindFirstChild("BoostChanged")
if not BoostChanged then
	BoostChanged = Instance.new("RemoteEvent")
	BoostChanged.Name = "BoostChanged"
	BoostChanged.Parent = RS
end

local state = {
	serverLuck = { mult = 1.0, expiresAt = 0, buyer = 0 }, -- default 1.0 (no effect)
}

local M = {}

-- Returns full serverLuck record; also auto-expires if time passed
function M.GetServerLuck()
	local sl = state.serverLuck
	if sl.expiresAt > 0 and os.time() >= sl.expiresAt then
		state.serverLuck = { mult = 1.0, expiresAt = 0, buyer = 0 }
		sl = state.serverLuck
		BoostChanged:FireAllClients("ServerLuck", sl)
	end
	return sl
end

-- Shorthand: value to multiply into rarity/luck math
function M.GetLuckMultiplierForPlayer(_plr)
	return M.GetServerLuck().mult or 1.0
end

-- Activate a server-wide luck boost (e.g., x2 for 15 minutes)
function M.ActivateServerLuck(multiplier:number, durationSeconds:number, buyerUserId:number?)
	local mult = tonumber(multiplier) or 2.0
	local dur  = math.max(60, tonumber(durationSeconds) or 900) -- clamp min 60s
	local exp  = os.time() + dur
	state.serverLuck = { mult = mult, expiresAt = exp, buyer = tonumber(buyerUserId) or 0 }
	BoostChanged:FireAllClients("ServerLuck", state.serverLuck)
end

-- Time left in seconds (0 if none)
function M.GetServerLuckRemaining()
	local sl = M.GetServerLuck()
	if sl.expiresAt <= 0 then return 0 end
	return math.max(0, sl.expiresAt - os.time())
end

return M
