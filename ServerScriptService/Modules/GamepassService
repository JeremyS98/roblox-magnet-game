-- GamepassService.lua
-- Centralized gamepass & developer product utilities.
-- Step 3: Add this module; no behavior change until other scripts call it.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- === REPLACE THESE WITH YOUR REAL IDS ===
local PASS = {
	SELL_ANYWHERE = 1111111, -- Gamepass ID (permanent)
	DOUBLE_XP     = 2222222, -- Gamepass ID (permanent)
	SUPPORTER     = 3333333, -- Gamepass ID (permanent)
}
local PRODUCT = {
	SERVER_LUCK_2X_15MIN = 4444444, -- Developer Product ID (consumable)
}
-- =======================================

local ownsCache = {}  -- [userId] = { [passId]=true/false, ... }

local M = {}

function M.PASS_IDS() return PASS end
function M.PRODUCT_IDS() return PRODUCT end

local function ensureUser(userId:number)
	ownsCache[userId] = ownsCache[userId] or {}
end

-- Returns true/false (cached). Pcalls Roblox API for first check.
function M.UserOwnsPass(userId:number, passId:number): boolean
	ensureUser(userId)
	if ownsCache[userId][passId] ~= nil then
		return ownsCache[userId][passId]
	end
	local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, userId, passId)
	ownsCache[userId][passId] = ok and owned == true
	return ownsCache[userId][passId]
end

-- Convenience helpers
function M.HasSellAnywhere(userId:number): boolean
	return M.UserOwnsPass(userId, PASS.SELL_ANYWHERE)
end
function M.HasDoubleXP(userId:number): boolean
	return M.UserOwnsPass(userId, PASS.DOUBLE_XP)
end
function M.HasSupporter(userId:number): boolean
	return M.UserOwnsPass(userId, PASS.SUPPORTER)
end

-- Optional: clear cache for leaving players
Players.PlayerRemoving:Connect(function(plr)
	ownsCache[plr.UserId] = nil
end)

-- Developer Product receipt handler
-- This sets a server-wide luck boost when the correct product is purchased.
MarketplaceService.ProcessReceipt = function(receiptInfo)
	if receiptInfo.ProductId == PRODUCT.SERVER_LUCK_2X_15MIN then
		local ok, Boosts = pcall(function() return require(script.Parent.Boosts) end)
		if ok and Boosts then
			-- 2x luck for 15 minutes (extend by re-buying)
			Boosts.ActivateServerLuck(2.0, 15*60, receiptInfo.PlayerId)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- If you add more products later, handle them here.
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

return M
