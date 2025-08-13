local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")

local Boosts = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Boosts"))
local GamepassService = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("GamepassService"))

-- Grant developer product purchases
MarketplaceService.ProcessReceipt = function(receiptInfo)
	-- receiptInfo = { PlayerId, PurchaseId, ProductId, CurrencyType }
	local productIds = GamepassService.PRODUCT_IDS()
	if productIds and receiptInfo.ProductId == productIds.SERVER_LUCK_2X_15MIN then
		-- Activate x2 server luck for 15 minutes (900 seconds)
		local ok, err = pcall(function()
			Boosts.ActivateServerLuck(2.0, 900)
		end)
		if not ok then
			warn("[Purchases] Failed to ActivateServerLuck:", err)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Not handled here; allow purchase
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

print("[Purchases] Receipt handler ready (Server Luck wired).")
