-- ServerScriptService/SupporterBridge.server (Script)
local RS  = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local CheckSupporter = RS:FindFirstChild("CheckSupporter")
if not CheckSupporter then
	CheckSupporter = Instance.new("RemoteFunction")
	CheckSupporter.Name = "CheckSupporter"
	CheckSupporter.Parent = RS
end

local Modules = SSS:WaitForChild("Modules")
local GamepassService = require(Modules:WaitForChild("GamepassService"))
local Admins          = require(Modules:WaitForChild("Admins"))

CheckSupporter.OnServerInvoke = function(plr)
	if Admins.IsAdmin(plr.UserId) then return true end
	if GamepassService and GamepassService.HasSupporter then
		return GamepassService.HasSupporter(plr.UserId) == true
	end
	return false
end
