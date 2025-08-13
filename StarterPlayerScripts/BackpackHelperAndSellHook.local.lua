-- BackpackHelperAndSellHook.local.lua
-- Non-invasive helper:
--   • Restores a small blue "B" button (bottom-left) to toggle the Backpack.
--   • Allows pressing B to toggle.
--   • Hooks any "Sell" buttons to prompt Sell Anywhere gamepass for non-owners.
--   • Works even if your BackpackUI structure is different; does NOT replace existing UI scripts.
-- Safe to keep alongside your current BackpackUI.local.lua.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")

local LOCAL = Players.LocalPlayer
local PG = LOCAL:WaitForChild("PlayerGui")

-- Remotes
local RequestBackpackRE     = RS:WaitForChild("RequestBackpack")
local BackpackDataRE        = RS:WaitForChild("BackpackData")
local SellAnywhereRE        = RS:WaitForChild("SellAnywhere")
local CheckSellAnywhereRF   = RS:WaitForChild("CheckSellAnywhere")
local GetGamepassIdsRF      = RS:WaitForChild("GetGamepassIds")

-- === Backpack toggle helpers ===
local function findBackpackGui()
	return PG:FindFirstChild("BackpackUI")
end

local function findAnyFrame(gui: Instance): Instance?
	if not gui then return nil end
	-- Common names first
	local names = {"Main","Root","Container","Background","Frame","BackpackFrame","Body"}
	for _,n in ipairs(names) do
		local f = gui:FindFirstChild(n, true)
		if f and f:IsA("Frame") then return f end
	end
	-- Fallback: first Frame descendant
	for _,d in ipairs(gui:GetDescendants()) do
		if d:IsA("Frame") then return d end
	end
	return nil
end

local function openBackpack()
	local gui = findBackpackGui()
	if gui then
		gui.Enabled = true
		local root = findAnyFrame(gui)
		if root then root.Visible = true end
		task.defer(function()
			pcall(function() RequestBackpackRE:FireServer() end)
		end)
		return true
	end
	return false
end

local function closeBackpack()
	local gui = findBackpackGui()
	if gui then
		local root = findAnyFrame(gui)
		if root then root.Visible = false end
		gui.Enabled = false
		return true
	end
	return false
end

local function toggleBackpack()
	local gui = findBackpackGui()
	if not gui then
		-- If UI not yet cloned, request and try again shortly
		pcall(function() RequestBackpackRE:FireServer() end)
		task.delay(0.25, openBackpack)
		return
	end
	if gui.Enabled then
		closeBackpack()
	else
		openBackpack()
	end
end

-- === Minimal bottom-left "B" button (only if none exists) ===
local function ensureBackpackButton()
	local existing = PG:FindFirstChild("BackpackOverlayHelper")
	if existing then return end

	local sg = Instance.new("ScreenGui")
	sg.Name = "BackpackOverlayHelper"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = PG

	local btn = Instance.new("TextButton")
	btn.Name = "BackpackToggle"
	btn.Size = UDim2.new(0, 32, 0, 32)
	btn.Position = UDim2.new(0, 20, 1, -52)
	btn.AnchorPoint = Vector2.new(0,1)
	btn.BorderSizePixel = 0
	btn.BackgroundColor3 = Color3.fromRGB(35, 115, 255) -- blue circle
	btn.Text = "B"
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.AutoButtonColor = true
	btn.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(toggleBackpack)
end

-- Toggle with keyboard "B"
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.B then
		toggleBackpack()
	end
end)

-- Make sure helper button exists
ensureBackpackButton()

-- If BackpackUI is added later, we still work
PG.ChildAdded:Connect(function(ch)
	if ch.Name == "BackpackUI" then
		-- optional: immediately enable quick open on first appearance
		-- openBackpack()
		-- Hook sell buttons when it spawns
		task.delay(0.1, function()
			local gui = ch
			for _,d in ipairs(gui:GetDescendants()) do
				if d:IsA("TextButton") and (d.Name == "SellButton" or (d.Text or ""):lower():find("sell")) then
					if not d:GetAttribute("SellHooked") then
						d:SetAttribute("SellHooked", true)
						d.MouseButton1Click:Connect(function()
							-- Check pass ownership
							local owns = false
							local okOwn, resOwn = pcall(function()
								return CheckSellAnywhereRF:InvokeServer()
							end)
							if okOwn then owns = (resOwn == true) end

							if owns then
								SellAnywhereRE:FireServer()
								return
							end

							-- Prompt purchase
							local ids
							pcall(function() ids = GetGamepassIdsRF:InvokeServer() end)
							local passId = (type(ids)=="table" and ids.SELL_ANYWHERE) or 0
							if type(passId)=="number" and passId > 0 then
								pcall(function()
									MarketplaceService:PromptGamePassPurchase(LOCAL, passId)
								end)
							end
						end)
					end
				end
			end
			-- Hook future buttons too
			gui.DescendantAdded:Connect(function(d)
				if d:IsA("TextButton") and (d.Name == "SellButton" or (d.Text or ""):lower():find("sell")) then
					if not d:GetAttribute("SellHooked") then
						d:SetAttribute("SellHooked", true)
						d.MouseButton1Click:Connect(function()
							local owns = false
							local okOwn, resOwn = pcall(function()
								return CheckSellAnywhereRF:InvokeServer()
							end)
							if okOwn then owns = (resOwn == true) end

							if owns then
								SellAnywhereRE:FireServer()
								return
							end

							local ids
							pcall(function() ids = GetGamepassIdsRF:InvokeServer() end)
							local passId = (type(ids)=="table" and ids.SELL_ANYWHERE) or 0
							if type(passId)=="number" and passId > 0 then
								pcall(function()
									MarketplaceService:PromptGamePassPurchase(LOCAL, passId)
								end)
							end
						end)
					end
				end
			end)
		end)
	end
end)

-- If Backpack already exists at start, hook sell buttons immediately
local existing = findBackpackGui()
if existing then
	PG.ChildAdded:Fire(existing) -- reuse the same logic path
end
