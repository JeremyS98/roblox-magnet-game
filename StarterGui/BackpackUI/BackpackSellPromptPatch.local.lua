-- BackpackSellPromptPatch.local.lua
-- Safe add-on: does not depend on a specific frame name and does not replace your existing BackpackUI script.
-- Drop this under: StarterGui/BackpackUI/BackpackSellPromptPatch.local.lua

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local MPS     = game:GetService("MarketplaceService")

local LOCAL   = Players.LocalPlayer

-- Remotes (created by server)
local SellAnywhereRE       = RS:WaitForChild("SellAnywhere")
local CheckSellAnywhereRF  = RS:WaitForChild("CheckSellAnywhere")
local GetGamepassIdsRF     = RS:WaitForChild("GetGamepassIds")

-- Find the BackpackUI ScreenGui and a host frame to attach the button to
local function findBackpackGui()
	local pg = LOCAL:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("BackpackUI", 5) or pg:FindFirstChild("BackpackUI")
	return gui
end

local function findHostFrame(gui)
	if not gui then return nil end
	-- Prefer a top-level Frame named "Main" if present
	local main = gui:FindFirstChild("Main", true)
	if main and main:IsA("Frame") then return main end
	-- Otherwise, take the first Frame descendant
	for _,d in ipairs(gui:GetDescendants()) do
		if d:IsA("Frame") then
			return d
		end
	end
	return nil
end

local function ensureSingleSellButton(parentFrame)
	if not parentFrame then return nil end
	-- Destroy duplicates by name, keep/return the first one we find or create a new one
	local keep = nil
	for _,c in ipairs(parentFrame:GetChildren()) do
		if c:IsA("TextButton") and c.Name == "SellButton" then
			if keep == nil then keep = c else c:Destroy() end
		end
	end
	if not keep then
		keep = Instance.new("TextButton")
		keep.Name = "SellButton"
		keep.Text = "Sell"
		keep.AutoButtonColor = true
		keep.Size = UDim2.new(0, 90, 0, 34)
		keep.AnchorPoint = Vector2.new(1, 0)
		keep.Position = UDim2.new(1, -60, 0, 12) -- near top-right
		keep.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- green
		keep.TextColor3 = Color3.new(1, 1, 1)
		keep.Font = Enum.Font.GothamBold
		keep.TextSize = 16
		keep.ZIndex = 50
		keep.Parent = parentFrame
	else
		-- normalize placement in case layout differs
		keep.AnchorPoint = Vector2.new(1, 0)
		keep.Position = UDim2.new(1, -60, 0, 12)
		keep.Size = UDim2.new(0, 90, 0, 34)
		keep.Text = "Sell"
		keep.Visible = true
	end
	return keep
end

local function promptSellAnywhereIfNeeded()
	-- Ownership check (server authority)
	local owns = false
	local ok1, res1 = pcall(function()
		return CheckSellAnywhereRF:InvokeServer()
	end)
	if ok1 then owns = res1 == true end

	if owns then
		SellAnywhereRE:FireServer()
		return
	end

	-- Prompt purchase if available
	local passIds = nil
	local ok2, res2 = pcall(function()
		return GetGamepassIdsRF:InvokeServer()
	end)
	if ok2 and type(res2) == "table" then passIds = res2 end
	local sellPassId = (passIds and passIds.SELL_ANYWHERE) or 0
	if type(sellPassId) == "number" and sellPassId > 0 then
		pcall(function()
			MPS:PromptGamePassPurchase(LOCAL, sellPassId)
		end)
	end
end

-- Connect once; avoid duplicate connections by cloning trick
local function resetConnections(btn)
	local parent = btn.Parent
	local clone = btn:Clone()
	clone.Parent = parent
	btn:Destroy()
	return clone
end

-- Bootstrap
local gui = findBackpackGui()
if gui then
	local frame = findHostFrame(gui)
	if frame then
		local btn = ensureSingleSellButton(frame)
		if btn then
			btn = resetConnections(btn)
			local clicking = false
			btn.MouseButton1Click:Connect(function()
				if clicking then return end
				clicking = true
				task.defer(function()
					promptSellAnywhereIfNeeded()
					task.wait(0.25)
					clicking = false
				end)
			end)
		end
	end
end

-- If the GUI is recreated (e.g., reopen backpack), try again
LOCAL.PlayerGui.ChildAdded:Connect(function(child)
	if child.Name == "BackpackUI" then
		task.delay(0.1, function()
			local frame = findHostFrame(child)
			if frame then
				local btn = ensureSingleSellButton(frame)
				if btn then
					btn = resetConnections(btn)
					local clicking = false
					btn.MouseButton1Click:Connect(function()
						if clicking then return end
						clicking = true
						task.defer(function()
							promptSellAnywhereIfNeeded()
							task.wait(0.25)
							clicking = false
						end)
					end)
				end
			end
		end)
	end
end)
