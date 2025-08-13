-- ServerScriptService/AdminBridge.server.lua
local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

-- Remotes
local IsAdminRF = RS:FindFirstChild("IsAdmin") or Instance.new("RemoteFunction", RS)
IsAdminRF.Name = "IsAdmin"

local AdminActivateLuckRE = RS:FindFirstChild("AdminActivateLuck")
if not AdminActivateLuckRE then
	AdminActivateLuckRE = Instance.new("RemoteEvent")
	AdminActivateLuckRE.Name = "AdminActivateLuck"
	AdminActivateLuckRE.Parent = RS
end

-- Modules
local Modules = SSS:WaitForChild("Modules")
local Admins  = require(Modules:WaitForChild("Admins"))

-- Optional Boosts access (for Luck activation)
local Boosts
pcall(function()
	local inst = Modules:FindFirstChild("Boosts") or Modules:FindFirstChild("Boosts.lua")
	if inst then Boosts = require(inst) end
end)

-- Who is admin?
IsAdminRF.OnServerInvoke = function(plr)
	return Admins.IsAdmin(plr.UserId)
end

-- Admin-only luck activation (15 min, x2)
if AdminActivateLuckRE then
	AdminActivateLuckRE.OnServerEvent:Connect(function(plr)
		if not Admins.IsAdmin(plr.UserId) then return end
		if Boosts and Boosts.ActivateServerLuck then
			Boosts.ActivateServerLuck(2.0, 15*60)
		end
	end)
end
