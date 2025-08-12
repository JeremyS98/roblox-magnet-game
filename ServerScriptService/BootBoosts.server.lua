-- BootBoosts.server.lua
-- Tiny bootstrap so Boosts module initializes (creates RemoteEvent).
-- Safe to keep even if no scripts read the boost yet.
local ok, Boosts = pcall(function() return require(script.Parent.Modules.Boosts) end)
if ok then
	print("[Boosts] ready. Server luck x"..tostring(Boosts.GetLuckMultiplierForPlayer(nil)).." (remaining "..tostring(Boosts.GetServerLuckRemaining()).."s)")
else
	warn("[Boosts] failed to load:", Boosts)
end
