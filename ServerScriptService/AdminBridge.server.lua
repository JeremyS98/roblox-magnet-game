-- ServerScriptService/AdminBridge.server.lua
local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local IsAdminRF = RS:FindFirstChild("IsAdmin") or Instance.new("RemoteFunction", RS)
IsAdminRF.Name = "IsAdmin"

local AdminActivateLuckRE = RS:FindFirstChild("AdminActivateLuck")
if not AdminActivateLuckRE then
	AdminActivateLuckRE = Instance.new("RemoteEvent")
	AdminActivateLuckRE.Name = "AdminActivateLuck"
	AdminActivateLuckRE.Parent = RS
end

local Modules = SSS:WaitForChild("Modules")
local Admins  = require(Modules:WaitForChild("Admins"))

local Boosts = nil
pcall(function()
	local inst = Modules:FindFirstChild("Boosts") or Modules:FindFirstChild("Boosts.lua")
	if inst then Boosts = require(inst) end
end)

IsAdminRF.OnServerInvoke = function(plr)
	return Admins.IsAdmin(plr.UserId)
end

AdminActivateLuckRE.OnServerEvent:Connect(function(plr)
	if not Admins.IsAdmin(plr.UserId) then return end
	if Boosts and Boosts.ActivateServerLuck then
		Boosts.ActivateServerLuck(2.0, 15*60)
	end
end)
