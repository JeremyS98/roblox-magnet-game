-- BootBoosts.server.lua (safe wait-for-module)
local SSS = game:GetService("ServerScriptService")
local Modules = SSS:WaitForChild("Modules")

-- Debug listing if something goes wrong
local function listChildren()
	for _, c in ipairs(Modules:GetChildren()) do
		print("[Modules] child:", c.Name, c.ClassName)
	end
end

local ok, BoostsOrErr = pcall(function()
	local BoostsModule = Modules:WaitForChild("Boosts", 10) -- waits up to 10s
	return require(BoostsModule)
end)

if ok and BoostsOrErr then
	local Boosts = BoostsOrErr
	print(("[Boosts] ready. Server luck x%s (remaining %ss)")
		:format(tostring(Boosts.GetLuckMultiplierForPlayer(nil)), tostring(Boosts.GetServerLuckRemaining())))
else
	warn("[Boosts] failed to load:", BoostsOrErr)
	listChildren()
end
