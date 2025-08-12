-- XPAdjust.lua
-- Returns adjusted XP amount (applies Double XP pass if enabled)

local SSS = game:GetService("ServerScriptService")
local Modules = SSS:WaitForChild("Modules")

local Flags = require(Modules:WaitForChild("FeatureFlags"))
local GP    = require(Modules:WaitForChild("GamepassService"))

local M = {}

function M.Adjust(plr, baseAmount:number): number
	baseAmount = tonumber(baseAmount) or 0
	if baseAmount <= 0 then return 0 end
	if Flags.DoubleXP and GP.HasDoubleXP(plr.UserId) then
		return math.floor(baseAmount * 2)
	end
	return baseAmount
end

return M
