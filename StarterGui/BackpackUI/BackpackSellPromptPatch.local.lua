-- BackpackSellPromptHook.local.lua
-- Purpose: If a player WITHOUT the Sell Anywhere pass clicks the existing Sell button,
--          prompt them to buy the pass. Owners keep current behavior.
-- Placement: StarterGui/BackpackUI/BackpackSellPromptHook.local.lua

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local MPS     = game:GetService("MarketplaceService")

local LOCAL   = Players.LocalPlayer

-- Remotes provided by server
local CheckSellAnywhereRF = RS:WaitForChild("CheckSellAnywhere")
local GetGamepassIdsRF    = RS:WaitForChild("GetGamepassIds")

-- Find the BackpackUI ScreenGui
local function getBackpackGui()
    local pg = LOCAL:WaitForChild("PlayerGui")
    local gui = pg:FindFirstChild("BackpackUI")
    if not gui then
        gui = pg.ChildAdded:Wait()
        while gui.Name ~= "BackpackUI" do
            gui = pg.ChildAdded:Wait()
        end
    end
    return gui
end

-- Detect a plausible Sell button under the BackpackUI
local function isSellButton(inst)
    if not inst or not inst:IsA("TextButton") then return false end
    if inst.Name == "SellButton" then return true end
    local t = (inst.Text or ""):lower()
    return t == "sell" or t:find("sell")
end

local function attachIfNeeded(btn)
    if not btn or not btn:IsA("TextButton") then return end
    if btn:GetAttribute("SellPromptHooked") then return end
    btn:SetAttribute("SellPromptHooked", true)

    btn.MouseButton1Click:Connect(function()
        -- Ask server: do we own the pass?
        local owns = false
        local ok1, res1 = pcall(function()
            return CheckSellAnywhereRF:InvokeServer()
        end)
        if ok1 then owns = res1 == true end
        if owns then
            -- Owner: let existing behavior proceed (server will sell)
            return
        end
        -- Non-owner: prompt to buy
        local ids = nil
        local ok2, res2 = pcall(function()
            return GetGamepassIdsRF:InvokeServer()
        end)
        if ok2 and type(res2) == "table" then ids = res2 end
        local passId = (ids and ids.SELL_ANYWHERE) or 0
        if type(passId) == "number" and passId > 0 then
            pcall(function()
                MPS:PromptGamePassPurchase(LOCAL, passId)
            end)
        end
    end)
end

-- Initial hookup
local gui = getBackpackGui()

-- Attach to any existing sell button(s)
for _,d in ipairs(gui:GetDescendants()) do
    if isSellButton(d) then
        attachIfNeeded(d)
    end
end

-- Attach to future buttons (when UI opens/closes)
gui.DescendantAdded:Connect(function(d)
    if isSellButton(d) then
        attachIfNeeded(d)
    end
end)
